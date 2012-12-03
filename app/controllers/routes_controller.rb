require 'zip/zipfilesystem'
require 'json'

class RoutesController < ApplicationController

  def index
    @routes=Route.all
  end

  def show
    db = SQLite3::Database.open "db/development.sqlite3"
    db.results_as_hash = true

    @id = Route.find(params[:id])
    @general_route = GeneralRoute.find(@id.general_route_id)
    @gps = db.execute "SELECT routes.name, gps_samples.latitude, gps_samples.longitude, nfc_samples.timestamp,nfc_samples.message, surveys.answer
                      FROM  nfc_samples INNER JOIN surveys
                      ON nfc_samples.id = surveys.nfc_sample_id
                      INNER JOIN gps_samples
                      ON nfc_samples.gps_sample_id = gps_samples.id
                      INNER JOIN routes
                      ON gps_samples.route_id=routes.id
                      WHERE routes.id='"+params[:id]+"'
                      AND surveys.answer <>  '<null>' ORDER BY nfc_samples.timestamp"


    if @gps.length==0 #se eliminar las rutas vacias

      Route.delete(@id)
      redirect_to general_route_path(:id => @general_route.id), notice: 'The empty sensed was delete'
    end
    #Procesar los datos para mandar solamente una hash con el timestamp, el mensaje,  y un string donde se concatenen
    #los mensajes que se van a mostrar en la gps.

    ##########################################################
    #Procesar los datos para en el archivo que se manda, se concatenen los elementos con la misma gps para que el mensaje y el answer muestren cosas concatenadas.

    #TO DO: Si es repetida la NFC (message y timestamp) y el answer de la survey, no concatenar ni el mensaje, ni la respuesta. Ejm PARADA/PARADA

    count = 0
    @gps_array = []

    while !@gps[count + 1].nil? #
      if @gps[count]["latitude"] == @gps[count + 1]["latitude"] && @gps[count]["longitude"] == @gps[count + 1]["longitude"]
        source_hash = {"name" => @gps[count]["name"], "latitude" => @gps[count]["latitude"], "longitude" => @gps[count]["longitude"], "timestamp" => @gps[count]["timestamp"], "message" => @gps[count]["message"] + "/" + @gps[count + 1]["message"], "answer" => @gps[count]["answer"] + "/" + @gps[count + 1]["answer"]}
        @gps_array << source_hash
        count = count + 2
        #elsif @gps[count]["message"] == "FIN"
        #  source_hash = {"name" => @gps[count]["name"], "latitude" => @gps[count]["latitude"], "longitude" => @gps[count]["longitude"], "timestamp" => @gps[count]["timestamp"], "message" => @gps[count]["message"], "answer" => @gps[count]["answer"]}
        #  @gps_array << source_hash
      else
        source_hash = {"name" => @gps[count]["name"], "latitude" => @gps[count]["latitude"], "longitude" => @gps[count]["longitude"], "timestamp" => @gps[count]["timestamp"], "message" => @gps[count]["message"], "answer" => @gps[count]["answer"]}
        @gps_array << source_hash
        count = count + 1
      end
    end

    source_hash = {"name" => @gps[@gps.length - 1]["name"], "latitude" => @gps[@gps.length - 1]["latitude"], "longitude" => @gps[@gps.length - 1]["longitude"], "timestamp" => @gps[@gps.length - 1]["timestamp"], "message" => @gps[@gps.length - 1]["message"], "answer" => @gps[@gps.length - 1]["answer"]}
    @gps_array << source_hash

    count = 0
    @gps_array2 = []

    while !@gps_array[count + 1].nil? #
      if @gps_array[count]["latitude"] == @gps_array[count + 1]["latitude"] && @gps_array[count]["longitude"] == @gps_array[count + 1]["longitude"]
        source_hash = {"name" => @gps_array[count]["name"], "latitude" => @gps_array[count]["latitude"], "longitude" => @gps_array[count]["longitude"], "timestamp" => @gps_array[count]["timestamp"], "message" => @gps_array[count]["message"] + "/" + @gps_array[count + 1]["message"], "answer" => @gps_array[count]["answer"] + "/" + @gps_array[count + 1]["answer"]}
        @gps_array2 << source_hash
        count = count + 2
        #elsif @gps[count]["message"] == "FIN"
        #  source_hash = {"name" => @gps[count]["name"], "latitude" => @gps[count]["latitude"], "longitude" => @gps[count]["longitude"], "timestamp" => @gps[count]["timestamp"], "message" => @gps[count]["message"], "answer" => @gps[count]["answer"]}
        #  @gps_array << source_hash
      else
        source_hash = {"name" => @gps_array[count]["name"], "latitude" => @gps_array[count]["latitude"], "longitude" => @gps_array[count]["longitude"], "timestamp" => @gps_array[count]["timestamp"], "message" => @gps_array[count]["message"], "answer" => @gps_array[count]["answer"]}
        @gps_array2 << source_hash
        count = count + 1
      end
    end

    source_hash = {"name" => @gps_array[@gps_array.length - 1]["name"], "latitude" => @gps_array[@gps_array.length - 1]["latitude"], "longitude" => @gps_array[@gps_array.length - 1]["longitude"], "timestamp" => @gps_array[@gps_array.length - 1]["timestamp"], "message" => @gps_array[@gps_array.length - 1]["message"], "answer" => @gps_array[@gps_array.length - 1]["answer"]}
    @gps_array2 << source_hash

    ##########################################################
    ##### Se encuentran los datos de pasajeros por hora...

    @passengers = Passenger.find_all_by_route_id(@id)
    @array = []
    @array << @passengers.to_json


    ################################################################
    #Se busca la capacidad de pasajeros que puede llevar el camión
    @nfc_samples = NfcSample.all :joins => {:gps_sample => :route}, :conditions => {:gps_samples => {:route_id => @id}}
    @bus_size = 0

    @nfc_samples.each do |nfc|
      if nfc["message"]=="INICIO"

        @survey2 = Survey.find_all_by_nfc_sample_id(nfc)

        if !@survey2.nil?
          if !@survey2[0].nil?
            if !@survey2[0].answer.nil?
              @bus_size = @survey2[0].answer.to_i #Obtener la capacidad de pasajeros que puede llevar el camion de la ruta sensada
            end
          end
        end

      end
    end

    #######################################################

    #######################################################
    #Sacar la duración de la ruta en horas, minutos y segundos

    #Se buscan todos los NFC de ese sensado
    @nfc_samples = NfcSample.all :joins => {:gps_sample => :route}, :conditions => {:gps_samples => {:route_id => @id}}

    @nfc_samples.each do |nfc|
      if nfc["message"]=="INICIO"
        @time_start = nfc.timestamp #Se obtiene el timestamp del inicio
      end

      if nfc["message"]=="FIN"
        @time_end = nfc.timestamp #Se obtiene el ti  mestamp del final
      end
    end

    route_duration = @time_end.to_i - @time_start.to_i

    duration_seconds = route_duration/1000

    seconds = duration_seconds.to_i
    @duration = format_time (seconds) #Duración de la ruta actual en horas, minutos, segundos

    ################################################

    #################################################
    #Crear un arreglo de coordenadas GPS para enviarselas al mapa a partir del INICIO y FIN de los NFC, aunque no tengan NFC
    #Se buscan todas las coordenadas de ese sensado
    @gps_all = GpsSample.find_all_by_route_id(@id)

    #######################################################
  end

  def format_time (timeElapsed) #time in seconds

    @timeElapsed = timeElapsed

    #find the seconds
    seconds = @timeElapsed % 60

    #find the minutes
    minutes = (@timeElapsed / 60) % 60

    #find the hours
    hours = (@timeElapsed/3600)

    #format the time

    return hours.to_s + ":" + format("%02d", minutes.to_s) + ":" + format("%02d", seconds.to_s)
  end

  def showAll
    db = SQLite3::Database.open "db/development.sqlite3"
    db.results_as_hash = true


    if !params[:route].nil?

      @ids=params[:route]
      route = Route.find(@ids[0])
      @general_route = GeneralRoute.find(route.general_route_id)


      @gps=Array.new
      @color=Array.new
      @x=Array.new
      @duration=Array.new

      @ids.each do |id|
        #@gps.push (db.execute "SELECT routes.name, gps_samples.latitude, gps_samples.longitude, nfc_samples.timestamp,nfc_samples.message, surveys.answer
        #                FROM  nfc_samples INNER JOIN surveys
        #                ON nfc_samples.id = surveys.nfc_sample_id
        #                INNER JOIN gps_samples
        #                ON nfc_samples.gps_sample_id = gps_samples.id
        #                INNER JOIN routes
        #                ON gps_samples.route_id=routes.id
        #                WHERE routes.id='"+id+"'
        #                AND surveys.answer <>  '<null>'")

        @gps.push (GpsSample.find_all_by_route_id(id))

        @color.push("%06x" % (rand * 0xffffff))


        @x.push(Passenger.where("route_id=?", id).group("route_id,count").order("count(count) DESC").first)


        @nfc_samples = NfcSample.all :joins => {:gps_sample => :route}, :conditions => {:gps_samples => {:route_id => id}}

        @nfc_samples.each do |nfc|
          if nfc["message"]=="INICIO"
            @time_start = nfc.timestamp #Se obtiene el timestamp del inicio
          end

          if nfc["message"]=="FIN"
            @time_end = nfc.timestamp #Se obtiene el ti  mestamp del final
          end
        end

        route_duration = @time_end.to_i - @time_start.to_i

        duration_seconds = route_duration/1000

        seconds = duration_seconds.to_i
        @duration.push(format_time (seconds)) #Duración de la ruta actual en horas, minutos, segundos




      end

      @c=@color.clone
      @color = @color.to_s.gsub!("[", "")
      @color = @color.to_s.gsub!("]", "")

    else
      redirect_to :back, notice: 'Select a route'
    end

  end

  def destroy
    # find only the location that has the id defined in params[:id]
    @route = Route.find(params[:id])

    # delete the location object and any child objects associated with it
    @route.destroy

    # redirect the user to index
    general_route=GeneralRoute.find(@route.general_route_id)
    redirect_to general_route_path(:id => general_route.id), notice: 'Route deleted'
  end

  def upload
    @general_route=GeneralRoute.find(params[:id])
    @routes=Route.find_all_by_general_route_id(@general_route.id)

    unless params[:file].nil?
      @general_route=GeneralRoute.find(params[:id])
      @file=params[:file]
      nfcArray=[]
      gpsArray=[]
      surveyArray = []

      #validar que sean archivos .json
      chkNameFile=@file.original_filename.split(/\./)
      if chkNameFile[1]=="zip"
        #crear un archivo temporar
        f = @file.tempfile.to_path

        #descomprime el archivo y recorre cada archivo
        Zip::ZipFile.open(f) do |zipfile|
          zipfile.each do |f|
            #lee el flujo de entrada de cada archivo
            a = f.get_input_stream.read

            #el .zip se toma como archivo también pero viene nulo, si no es nulo entonces es un archivo que se va a descomprimir
            #1. Validar que tipo de archivo es y concatenar en un arreglo todas las hash que correspondan al mismo tipo
            unless a.nil?
              json=JSON.parse(a)

              #si es tipo NFC el archivo, se almacenara en el arreglo NFC
              if json[0]["dataType"]=="NFC"
                nfcArray=nfcArray +json
              else
                #si es tipo GPS se alamacenara en el arreglo GPS
                if json[0]["dataType"]=="GPS"
                  gpsArray=gpsArray+ json
                else
                  #si no es ninguno de los dos tipos entonces es tipo survey, por lo que
                  #a cada elemento del json se le agregara el atributo timestamp tomado del nombre del archivo
                  #y se agregara al arreglo S
                  json.each do |j|
                    getTime = f.to_s.split(/\//)
                    getTime[1] = getTime[1].gsub!("survey", "")
                    getTime[1] = getTime[1].gsub!(".json", "")
                    j["timestamp"] = getTime[1]
                  end
                  surveyArray=surveyArray + json
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


        timeInicio=[]
        timeFinal=[]
        flag=true
        i=0
        nfcArray.each do |nfc|
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
          unless timeFinal[idx].nil?

            #Crear un sensado
            #obtener todas los nombre de las rutas para saber el numero que sigue
            routes=Route.all
            if routes.length==0
              name="Sensed 1"
            else
              i= routes[routes.length-1].id.to_i
              name = "Sensed "+(i+1).to_s
            end

            #crear la ruta

            route = Route.new("name" => name, "general_route_id" => @general_route.id)
            route.save!

            route = Route.find_by_name(name)


            #Obtener el id de la ruta y buscar los gps que corresponden
            gpsArray.each do |gps|
              # Se resta 86400000 lo equivalente a un día en milisegundos por que los archivos estan
              # desfasados por un dia

              if GpsSample.find_by_timestamp(gps["timestamp"]).nil? #Descomentar o comentar
                if inicio[idx].to_i <= gps["timestamp"].to_i-86400000 && gps["timestamp"].to_i-86400000 <= timeFinal[idx].to_i

                  gps = GpsSample.new("latitude" => gps["latitude"],
                                      "longitude" => gps["longitude"],
                                      "timestamp" => gps["timestamp"],
                                      "route_id" => route.id)
                  gps.save!

                end
              end
            end

            #Falta realizar el match entre las NFCs y las coordenadas, así como asignarle a cada NFC su
            #survey para mostrarse en el globito del mapa.

            #Obtener todos los gps de la ruta creada
            gpsRuta = GpsSample.find_all_by_route_id(route)
            error = 60000 #milisegundos que se van a dar como máximo de diferencia para asignar un nfc a un gps
            act = 0 #apuntador actual del gps (para recorrerlo del último que encontro en adelante)


            nfcArray.each do |nfc|
              #El primer Nfc Inicio se asigna al primer gps
              if nfc["timestamp"]==inicio
                nfcRuta = NfcSample.new("message" => nfc["message"],
                                        "timestamp" => nfc["timestamp"], #gpsRuta[0].timestamp, #["timestamp"], #ponerle el tiempo de la gps???
                                        "gps_sample_id" => gpsRuta[0].id)

                nfcRuta.save!
              else
                #si el Nfc es mayor a inicio y menor a final, se buscará el gps con menor diferencia
                if nfc["timestamp"]>inicio && nfc["timestamp"]<timeFinal[idx]
                  #al gps se le resta un día en por el desfase de tiempos
                  dif = gpsRuta[act].timestamp.to_i-86400000-nfc["timestamp"] #Calcula la diferencia, se le resta un día
                  min = dif #diferencia minima
                  j = act #apuntador para buscar el menor

                  while error > dif && !gpsRuta[j+1].nil? #mientras que el error sea mayor al a diferencia o se termine de recorrer el arreglo
                    if dif.abs < min.abs #si la diferencia es menor al mínimo entonces hay un nuevo mínimo
                      min = dif
                      act = j
                    end
                    j=j+1 #incremento el apuntador
                    dif=gpsRuta[j].timestamp.to_i-86400000-nfc["timestamp"] #calculo la nueva diferencia
                  end

                  if error > min.abs #si el error es mayor al mínimo entonces guardo el nfc con el id de la ruta actual
                    nfcRuta = NfcSample.new("message" => nfc["message"],
                                            "timestamp" => nfc["timestamp"],
                                            "gps_sample_id" => gpsRuta[act].id)
                    nfcRuta.save!
                  end

                else
                  #si el NFC es igual a fin se asigna al último gps
                  if  nfc["timestamp"]==timeFinal[idx]
                    nfcRuta = NfcSample.new("message" => nfc["message"],
                                            "timestamp" => nfc["timestamp"], #asignarle el tiempo de la gps
                                            "gps_sample_id" => gpsRuta[gpsRuta.length-1].id)
                    nfcRuta.save!
                  end
                end
              end
            end


            #Hacer el match de las surveys con el nfc

            nfcRoute = NfcSample.all :joins => {:gps_sample => :route}, :conditions => {:gps_samples => {:route_id => route.id}}
            act = 0
            error = 20000 #menor porcentaje de error y menor perdida de información
            surveyArray.each do |survey|
              #si el survey es mayor a inicio y menor a final mas 1 min, se buscará el gps con menor diferencia
              if survey["timestamp"].to_i>inicio && survey["timestamp"].to_i<(timeFinal[idx]+60000)
                dif = nfcRoute[act].timestamp.to_i-survey["timestamp"].to_i #Calcula la diferencia,
                min = dif #diferencia minima
                ap = act #apuntador para buscar el menor

                while error >= dif && !nfcRoute[ap+1].nil? #mientras que el error sea mayor al a diferencia o se termine de recorrer el arreglo
                  if dif >= min #si la diferencia es menor al mínimo entonces hay un nuevo mínimo
                    min = dif
                    act = ap
                  end
                  ap=ap+1 #incremento el apuntador
                  dif=nfcRoute[ap].timestamp.to_i-survey["timestamp"].to_i #calculo la nueva diferencia
                end

                if error >= min.abs #si el error es mayor al mínimo entonces guardo el survey con el id del nfc actual

                  surveyRoute = Survey.new("answer" => survey["answer"],
                                           "timestamp" => survey["timestamp"],
                                           "nfc_sample_id" => nfcRoute[act].id)
                  surveyRoute.save!
                end

                #Se agrega un survey para las etiquetas FIN
                if nfcRoute[ap].message=="FIN"
                  if Survey.find_by_timestamp(nfcRoute[ap].timestamp).nil?
                    surveyRoute = Survey.new("answer" => "FIN",
                                             "timestamp" => nfcRoute[ap].timestamp,
                                             "nfc_sample_id" => nfcRoute[ap].id)
                    surveyRoute.save!
                  else
                    if Survey.find_by_timestamp(nfcRoute[ap].timestamp).answer=!"FIN"
                      surveyRoute = Survey.new("answer" => "FIN",
                                               "timestamp" => nfcRoute[ap].timestamp,
                                               "nfc_sample_id" => nfcRoute[ap].id)
                      surveyRoute.save!

                    end
                  end
                end
              end
            end
          end
        end

        ######################################################
        #Si un NFC de INICIO no tiene surveys, crearlas... Tiene un problema: si dos NFC coinciden en la coordenada, se muestra en el globito solo el mensaje de la útima NFC de esa coordenada.

        routes = Route.find_all_by_general_route_id(@general_route.id)
        routes.each do |r|
          @nfc_samples = NfcSample.all :joins => {:gps_sample => :route}, :conditions => {:gps_samples => {:route_id => r.id}}

          @nfc_samples.each do |nfc|
            if nfc["message"]=="INICIO"

              #@survey2 = Survey.find_all_by_nfc_sample_id(nfc)

              if Survey.find_all_by_nfc_sample_id(nfc.id).length == 0
                #if @survey2.nil?
                survey_Inicio1 = Survey.new("answer" => "25",
                                            "timestamp" => nfc.timestamp,
                                            "nfc_sample_id" => nfc.id)
                survey_Inicio1.save!

                survey_Inicio2 = Survey.new("answer" => "14",
                                            "timestamp" => nfc.timestamp,
                                            "nfc_sample_id" => nfc.id)
                survey_Inicio2.save!

              end

            end
          end
        end

        ##########################Fin de crear las surveys cuando un INICIO no tiene

        routes = Route.find_all_by_general_route_id(@general_route.id)
        routes.each do |r|
          gps = GpsSample.find_all_by_route_id(r.id)
          if gps.length==0
            Route.delete(r)
          end
        end

        routes = Route.find_all_by_general_route_id(@general_route.id)
        routes.each do |r|
          passengers(r.id)
        end


      end
      redirect_to routes_upload_path(:id => @general_route.id), notice: 'Successful load'
    end
  end

  def passengers (id)

    @nfc_samples = NfcSample.all :joins => {:gps_sample => :route}, :conditions => {:gps_samples => {:route_id => id}}
    @survey = Survey.all :joins => {:nfc_sample => {:gps_sample => :route}}, :conditions => {:gps_samples => {:route_id => id}}

    @passengers_number = 0 #variable para almacenar el núnmero de pasajeros por hora.

    @nfc_samples.each do |nfc|
      if nfc["message"]=="INICIO"

        @survey2 = Survey.find_all_by_nfc_sample_id(nfc)

        if !@survey2.nil?
          if !@survey2[0].nil?
            if !@survey2[0].answer.nil?
              @bus_size = @survey2[0].answer.to_i #Obtener la capacidad de pasajeros que puede llevar el camion de la ruta sensada
            end
          end
          #@bus_size = @survey2[0].answer.to_i

          if !@survey2[1].nil?
            if !@survey2[1].answer.nil?
              @passengers_number = @survey2[1].answer.to_i #Sacar la segunda survey que se almacenó con el id de la nfc de inicio

              @passengers = Passenger.new("timestamp" => nfc.timestamp,
                                          "count" => @passengers_number,
                                          "route_id" => id)
              @passengers.save!
            end
          end

        end
      end

      if nfc["message"]=="SUBIDA" #Si el mensaje es subida, entonces le sumamos la cantidad al numero de pasajeros actuales
        @survey3 = Survey.find_all_by_nfc_sample_id(nfc)
        # @passengers_rep = Passenger.find_all_by_timestamp(nfc)

        if !@survey3.nil?
          @survey3.each do |surv|
            if Passenger.find_all_by_timestamp(nfc.timestamp).length == 0 #Para cuando se repita la survey con el mismo nfc_id, solo escribir una
              if !surv.answer.nil?
                answer = surv.answer.to_i
                if answer.is_a?(Numeric) && answer != 0
                  @passengers_number = @passengers_number + surv.answer.to_i
                  @passengers = Passenger.new("timestamp" => nfc.timestamp,
                                              "count" => @passengers_number,
                                              "route_id" => id)
                  @passengers.save!
                end
              end
            end
          end
        end

      end

      if nfc["message"]=="BAJADA" #Si el mensaje es bajada, entonces restamos la cantidad en answer al numero de pasajeros.
        @survey3 = Survey.find_all_by_nfc_sample_id(nfc)
        # @passengers_rep = Passenger.find_all_by_timestamp(nfc)

        if !@survey3.nil?
          @survey3.each do |surv|
            if Passenger.find_all_by_timestamp(nfc.timestamp).length == 0 #Para cuando se repita la survey con el mismo nfc_id, solo escribir una
              if !surv.answer.nil?
                answer = surv.answer.to_i
                if answer.is_a?(Numeric) && answer != 0
                  #preguntar si es string foo.is_a?(String) 1.is_a? Numeric var.is_a? String var.is_a? Numeric

                  @passengers_number = @passengers_number - surv.answer.to_i
                  @passengers = Passenger.new("timestamp" => nfc.timestamp,
                                              "count" => @passengers_number,
                                              "route_id" => id)
                  @passengers.save!
                end
              end
            end
          end
        end

      end

    end
  end


end
