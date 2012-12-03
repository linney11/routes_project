

function drawVisualization(bus_size, container, array) {
    //var activitiesJSON = eval('(' + activities + ')');
    var activitiesArray = eval('(' + array + ')');

    var limit = eval('(' + bus_size + ')');

    //alert(array)
    //alert(activitiesArray)

    var header = ['Hour', 'bus_size'];
    var data = [[]];



    for (var user = 0; user < activitiesArray.length; user++) {

        var JSON = eval('(' + activitiesArray[user] + ')');

        //alert(JSON[0].count)

        header[header.length] = 'Sensed' + JSON[0].route_id;

        var time;
        var hour;
        var minutes;
        var minutes_string;
        var seconds;

        //var limit = 25


        for (var hs = 0; hs < JSON.length; hs++) {
            time = new Date(JSON[hs].timestamp);
            hour = time.getHours();
            minutes = time.getMinutes();

            if (minutes < 10){
                minutes_string =  '0' + minutes
            }
            else{
                minutes_string = minutes
            }

            seconds = time.getSeconds();
//          data[hs + 1] = [(hour+hs) + ':00', 400000, 343440, 117120, 6000 , 1200, sums[hs] / days];
            if (user != 0) {
                data[hs + 1][data[hs + 1].length] = JSON[hs].count;
            }
            else { //Si es dato de una sola serie (por ejemplo de 1 ruta)
                data[hs + 1] = [hour + ':' + minutes_string, limit, JSON[hs].count];
            }

        }

    }

    data[0] = header;

    var data2 = google.visualization.arrayToDataTable(data);

    var options = {
        title:'Number of passengers through time',
        vAxis:{title:"Number of passengers", minValue: 0},
        hAxis:{title:"Time"},
        seriesType:"line", color: 'blue', pointSize:5,
        //series: {5: {type: "line", pointSize: 5, color: 'red'},4: {type: "line", pointSize: 5, color: 'blue'},3: {type: "line", pointSize: 5, color: 'yellow'}}
        series:{0:{type:"area", pointSize:0, color: '#CCCCFF'}}
    };

//    var options = {
//        title:'Number of passengers through time',
//        vAxis:{title:"Number of passengers"},
//        hAxis:{title:"Time"},
//        seriesType:"area", color: '#DCDCDC', pointSize:0,
//        //series: {5: {type: "line", pointSize: 5, color: 'red'},4: {type: "line", pointSize: 5, color: 'blue'},3: {type: "line", pointSize: 5, color: 'yellow'}}
//        series:{1:{type:"line", pointSize:5, color: 'blue'}}
//    };


//    var options = {
//        title : 'Monthly Coffee Production by Country',
//        vAxis: {title: "Cups"},
//        hAxis: {title: "Month"},
//        seriesType: "area",
//        series: {5: {type: "line", pointSize: 5, color: 'red'},4: {type: "line", pointSize: 5, color: 'blue'},3: {type: "line", pointSize: 5, color: 'yellow'}}
//    };

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
