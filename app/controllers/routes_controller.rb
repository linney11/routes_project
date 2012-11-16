require 'zip/zipfilesystem'
require 'json'

class RoutesController < ApplicationController

  def index
      @routes=Route.all
  end

  def show
    @id = Route.find(params[:id])
    @gps = GpsSample.find_all_by_route_id(params[:id])

  end

  def upload
    if !params[:file].nil?
      @file=params[:file]
      @NFC=[]
      @GPS=[]
      @S = []

      #validar que sean archivos .json
      chkNameFile=@file.original_filename.split(/\./)
      if chkNameFile[1]=="zip"
        #crear un archivo temporar
        f = @file.tempfile.to_path

        #descomprime el archivo y recorre cada archivo
        Zip::ZipFile.open(f) do |zipfile|
          zipfile.each do |f|
            #lee el flujo de entrada de cada archivo
            a =   f.get_input_stream.read

            #el .zip se toma como archivo también pero viene nulo, si no es nulo entonces es un archivo que se va a descomprimir
            #1. Validar que tipo de archivo es y concatenar en un arreglo todas las hash que correspondan al mismo tipo
            if !a.nil?
              json=JSON.parse(a)

              #si es tipo NFC el archivo, se almacenara en el arreglo NFC
              if json[0]["dataType"]=="NFC"
                @NFC=@NFC +json
              else
                #si es tipo GPS se alamacenara en el arreglo GPS
                if json[0]["dataType"]=="GPS"
                  @GPS=@GPS+ json
                else
                  #si no es ninguno de los dos tipos entonces es tipo survey, por lo que
                  #a cada elemento del json se le agregara el atributo timestamp tomado del nombre del archivo
                  #y se agregara al arreglo S
                  json.each do |j|
                    getTime = f.to_s.split(/\//)
                    getTime[1] = getTime[1].gsub!("survey","")
                    getTime[1] = getTime[1].gsub!(".json","")
                    j["timestamp"] = getTime[1]
                  end
                  @S=@S + json
                end
              end
            end
          end
        end



            #2. Se examinará el arreglo NFC, donde se encuentre el primer inicio se buscará el primer fin, y se almacenaran
            #   en los arreglos Incio y fin los timestamp
            #   Ya que se tengan el inicio y fin, se creará una nueva ruta al modelo Rutas
            #   Por cada Elemento que este en el arreglo fin, cuyo timestamp este entre el inicio y fin, se agregarán a
            #   la base de datos y se asociarán a la Ruta creada
            #   Se hara esto por cada Inicio y Fin Encontrado

        @hola=[]

        @x=[]
            timeInicio=[]
            timeFinal=[]
            flag=true
            i=0
            @NFC.each do |nfc|
              if nfc["message"]=="INICIO" && flag==true
                timeInicio[i]=nfc["timestamp"]
                flag=false
              else
                if  nfc["message"]=="FIN" && flag==false
                  timeFinal[i]=nfc["timestamp"]
                  i = i+1
                  flag=true
                end
              end
            end

          #Se va a recorrer los arreglos, y si existen un inicio con un fin entonces
          # se va agregar a la bd una nueva ruta y se van a buscar los archivos gps
          # y almacenara con el id de esa ruta

            timeInicio.each_with_index do |inicio, idx|
              #si existe una ruta completa
              if !timeFinal[idx].nil?

                #Crear una ruta
                #obtener todas los nombre de las rutas para saber el numero que sigue
                @routes=Route.all
                if @routes.length==0
                  name="RUTA 1"
                else
                   i= @routes[@routes.length-1].id.to_i
                  name = "RUTA "+(i+1).to_s
                end

                #crear la ruta

                @route = Route.new("name"=>name)
                @route.save!

                @route = Route.find_by_name(name)


                #Obtener el id de la ruta y buscar los gps que corresponden
                @GPS.each do |gps|
                 # Se resta 86400000 lo equivalente a un día en milisegundos por que los archivos estan
                 # desfasados por un dia
                  if GpsSample.find_by_timestamp(gps["timestamp"]).nil?
                   if inicio[idx].to_i <= gps["timestamp"].to_i-86400000 && gps["timestamp"].to_i-86400000 <= timeFinal[idx].to_i

                     @gps = GpsSample.new("latitude"=>gps["latitude"],
                                           "longitude"=>gps["longitude"],
                                           "timestamp"=>gps["timestamp"],
                                           "route_id"=>@route.id)
                     @gps.save!

                   end
                  end
                end

                #Falta realizar el match entre las NFCs y las coordenadas, así como asignarle a cada NFC su
                #survey para mostrarse en el globito del mapa.

                #Obtener todos los gps de la ruta creada
                gpsRuta = GpsSample.find_all_by_route_id(@route)
                error = 60000 #milisegundos que se van a dar como máximo de diferencia para asignar un nfc a un gps
                act = 0 #apuntador actual del gps (para recorrerlo del último que encontro en adelante)


                @NFC.each do |nfc|
                  #El primer Nfc Inicio se asigna al primer gps
                  if nfc["timestamp"]==inicio
                    @nfcRuta = NfcSample.new("message"=>nfc["message"],
                                             "timestamp"=>nfc["timestamp"],
                                             "gps_sample_id"=>gpsRuta[0].id)

                    @nfcRuta.save!
                  else
                    #si el Nfc es mayor a inicio y menor a final, se buscará el gps con menor diferencia
                    if nfc["timestamp"]>inicio && nfc["timestamp"]<timeFinal[idx]
                      #al gps se le resta un día en por el desfase de tiempos
                      dif = gpsRuta[act].timestamp.to_i-86400000-nfc["timestamp"]   #Calcula la diferencia, se le resta un día
                      min = dif   #diferencia minima
                      j = act #apuntador para buscar el menor

                      while error > dif && !gpsRuta[j+1].nil?   #mientras que el error sea mayor al a diferencia o se termine de recorrer el arreglo
                          if dif.abs < min.abs #si la diferencia es menor al mínimo entonces hay un nuevo mínimo
                            min = dif
                            act = j
                          end
                        j=j+1   #incremento el apuntador
                        dif=gpsRuta[j].timestamp.to_i-86400000-nfc["timestamp"]   #calculo la nueva diferencia
                      end

                      if error > min.abs   #si el error es mayor al mínimo entonces guardo el nfc con el id de la ruta actual
                        @nfcRuta = NfcSample.new("message"=>nfc["message"],
                                                 "timestamp"=>nfc["timestamp"],
                                                 "gps_sample_id"=>gpsRuta[act].id)
                        @nfcRuta.save!
                      end

                    else
                      #si el NFC es igual a fin se asigna al último gps
                      if  nfc["timestamp"]==timeFinal[idx]
                        @nfcRuta = NfcSample.new("message"=>nfc["message"],
                                                 "timestamp"=>nfc["timestamp"],
                                                 "gps_sample_id"=>gpsRuta[gpsRuta.length-1].id)
                        @nfcRuta.save!
                      end

                    end
                  end
                end


              #Hacer el match de las surveys con el nfc
              # @NfcRoute = NfcSample.all
              #@NfcRoute = NfcSample.joins(:gps_sample, :route)

                #@NfcRoute = NfcSample.all :joins => {:gps_sample => :route}, :conditions => {'gps_sample.route_id' => '@route.id'}

                @NfcRoute = NfcSample.all :joins => {:gps_sample => :route}, :conditions => {:gps_samples => {:route_id => @route.id}}

 #               @nfcR = NfcSample.find_by_sql("SELECT *
 #FROM gps_samples INNER JOIN routes
 #  ON gps_samples.route_id = routes.id Inner JOIN nfc_samples
 #  ON nfc_samples.gps_id=gps_samples.id
 #WHERE routes.id='"+@route.id.to_s+"'")



               #@NfcRoute = NfcSample.find_by_sql("SELECT * FROM nfc_samples INNER JOIN gps_samples ON nfc_samples.gps_id = gps_samples.id INNER JOIN routes ON gps_samples.route_id = '" + @route.id.to_s + "'")
               # @NfcRoute = NfcSample.find_by_sql("SELECT * FROM nfc_samples INNER JOIN gps_samples ON nfc_samples.gps_id = gps_samples.id INNER JOIN routes ON gps_samples.route_id = routes.id")
                #'" + tuVariable + "'"
                #SELECT posts.* FROM posts
                #INNER JOIN categories ON posts.category_id = categories.id
                #INNER JOIN comments ON comments.post_id = posts.id

                ap=0 # Apuntador para recorrer el archivo de NFC.

                @S.each do |survey|
                  if survey["timestamp"].to_i > inicio && survey["timestamp"].to_i < timeFinal[idx]+60000
                    while !@NfcRoute[ap].nil?
                    dif = survey["timestamp"].to_i - @NfcRoute[ap].timestamp.to_i  #Calcula la diferencia
                    #min = dif   #diferencia minima
                    #j = ap #apuntador para buscar el menor
                    #while error > dif && !gpsRuta[j+1].nil?   #mientras que el error sea mayor al a diferencia o se termine de recorrer el arreglo
                    #  if dif.abs < min.abs #si la diferencia es menor al mínimo entonces hay un nuevo mínimo
                    #    min = dif
                    #    act = j
                    #  end
                    #  j=j+1   #incremento el apuntador
                    #  dif=gpsRuta[j].timestamp.to_i-86400000-nfc["timestamp"]   #calculo la nueva diferencia
                    #end
                    #
                    if error > dif  && dif > -1 #si el error es mayor al la diferencia y es positivo entonces guardo el nfc con el id de la ruta actual
                      @surveyRoute = Survey.new("answer"=>survey["answer"],
                                               "timestamp"=>survey["timestamp"],
                                               "nfc_sample_id"=>@NfcRoute[ap].id)
                      @surveyRoute.save!
                    end
                    ap=ap+1
                    end
                  end
                end



              end

            end

      end
    end

    @routes=Route.all

  end

end
