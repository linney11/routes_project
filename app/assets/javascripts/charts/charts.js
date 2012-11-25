

function drawVisualization(activities, container, array) {
    var activitiesJSON = eval('(' + activities + ')');
    var activitiesArray = eval('(' + array + ')');

    //alert(array)
    //alert(activitiesArray)

    var header = ['Hour'];
    var data = [[]];

    for (var user = 0; user < activitiesArray.length; user++) {

        var JSON = eval('(' + activitiesArray[user] + ')');

        //alert(JSON[0].count)

        header[header.length] = 'Route' + JSON[0].route_id;



        //todo: hacer el techo de esta operacion
//        var days = JSON.length / 24;
//
//        var sums = [];

//        for (var i = 0; i < 24; i++) {
//            sums[i] = 0;
//        }

//        for (var d = 0; d < days; d++){
//            var offset = d * 24;
//            for (var h = 0; h < 24; h++){
//                sums[h] += JSON[offset + h].count;
//            }
//        }

        var time;
        var hour;

        for (var hs = 0; hs < JSON.length; hs++) {
            time = new Date(JSON[hs].timestamp);
            hour = time.getHours();
//          data[hs + 1] = [(hour+hs) + ':00', 400000, 343440, 117120, 6000 , 1200, sums[hs] / days];
            if (user != 0) {
                data[hs + 1][data[hs + 1].length] = JSON[hs].count;
            }
            else { //Si es dato de una sola serie (por ejemplo de 1 ruta)
                data[hs + 1] = [(hour + hs) + ':00', JSON[hs].count];
            }

        }

//        for (var hs = 0; hs < 24; hs++) {
////          data[hs + 1] = [(hour+hs) + ':00', 400000, 343440, 117120, 6000 , 1200, sums[hs] / days];
//            if (user != 0) { // Va concatenando el valor de cada serie a cada elemento del arreglo.
//                data[hs + 1][data[hs + 1].length] = sums[hs] / days;
//            }
//            else { //Si es dato de una sola serie (por ejemplo de 1 ruta)
//                data[hs + 1] = [(hour + hs) + ':00', sums[hs] / days];
//            }
//
//        }
    }

    data[0] = header;

    var data2 = google.visualization.arrayToDataTable(data);

    var options = {
        title:'Average of activity Counts per Hour for Intensity Ranges',
        vAxis:{title:"Activity Counts"},
        hAxis:{title:"Hours"},
        seriesType:"line", pointSize:5
        //series: {5: {type: "line", pointSize: 5, color: 'red'},4: {type: "line", pointSize: 5, color: 'blue'},3: {type: "line", pointSize: 5, color: 'yellow'}}
//        series:{5:{type:"line", pointSize:5, color:'red'}}
    };

    var chart = new google.visualization.ComboChart(document.getElementById('container'));
    chart.draw(data2, options);
}

function timeConverter(timestamp) {
    var a = new Date(timestamp);
    var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    var year = a.getFullYear();
    var month = months[a.getMonth()];
    var date = a.getDate();
    var hour = a.getHours();
    var min = a.getMinutes();
    var sec = a.getSeconds();
    var time = date + ',' + month + ' ' + year + ' ' + hour + ':' + min + ':' + sec;
    return time;
}
