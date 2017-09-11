$(function(){
    $(".btnCancel").bind("click", Cancel);
    $(".btnEdit").bind("click", Edit);
});

function Cancel() {
    alert ("Cancel: " + playerID);
    var Epoch = (+new Date()) / 1000;
    
    //update player data
    jsonData = '{"cancelled": Epoch }';
    alert (jsonData);
    break;
    
    $.ajax({
            url: "/roster/team.json",
            type: 'post',
            dataType: "json",
            contentType: "application/json; charset=utf-8",
            //processData: false,
            data: jsonData,
            crossDomain: true,
            //headers: { "Timezone": getTimezone() },
            success: function (response) {
                console.log ("newId=" + response.id);
               
                //add row to html table
                removeButton = ' <button type="button" class="btn btn-link" onClick="timer.deleteRow(' + response.id + ')"><span class="glyphicon glyphicon-remove"></button></td>';
                rowHtml = '<tr id="row_' + response.id + '"><td>' + gametime + '</td><td>' + eventName + removeButton + '</td></tr>';
                if ($('#myEvents tbody tr').length == 0) {
                    $('#myEvents  tbody').append(rowHtml);        
                } else {
                    $('#myEvents > tbody > tr:first').before(rowHtml);        
                }    
            },
            error: function (xhr, status, error) {
                console.log("jsonData: " . jsonData);
                console.log("ERROR - xhr.status: " + xhr.status + '\nxhr.responseText: ' + xhr.responseText + '\nxhr.statusText: ' + xhr.statusText + '\nError: ' + error + '\nStatus: ' + status);
            }
        });
}

