// Refresh interval in milliseconds
var refreshInterval = 1000;

// Set timer to send request every N milliseconds
var tid = setInterval(checkExport, refreshInterval);
var t = 0;

function checkExport() {
  $.getJSON(checkUrl, function(data){
    var html = '';
    if(data.status == 'ok'){
      clearInterval(tid);
      window.location = data.url;
      html+= '<p style="background:lightgreen; padding:5px">';
      html+= data.message;
      html+= '</p>';
      html+= '<p>Vous pouvez fermer cette fenêtre une fois le fichier téléchargé.</p>';
      $('#waitExport').html(html);
    }
    else if(data.status == 'error'){
      html+= '<p style="background:orange; padding:5px">';
      html+= data.message;
      html+= '</p>';
      html+= '<p>Vous pouvez fermer cette fenêtre.</p>';
      $('#waitExport').html(html);
      clearInterval(tid);
    }
    else if(data.status == 'wait'){
      t+=1;
      html+= '<p style="background:lightblue; padding:5px">';
      html+= data.message;
      html+= ' (' + t + ' secondes)';
      html+= '</p>';
      $('#waitExport').html(html);
    }
  });
}
