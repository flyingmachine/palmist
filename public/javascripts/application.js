$(function(){
  var query_types = ["select", "update", "insert", "delete", "show"]
  
  //show/hide for query sets
  $(".queries-wrapper h2 a.show-hide-all").each(function(){
    $(this).click(function(){
      $(this).parent().parent().find(".queries").toggle();
    });
  })
  
  // show/hide for types of queries
  var show_hide_queries = function(){
    $(this).parent().parent().find(".queries ." + this.className).toggle();
    return false;
  }
  
  for(var i = 0; i < query_types.length; i++){
    $(".queries-wrapper .show-hide a").click(show_hide_queries);
  }
  
  $(".queries-wrapper .show-hide a.all").click(function(){
    $(this).parent().parent().find(".queries").toggle();
  });


  //hide all queries, types of queries
  var show_hide_all_queries = function(){
    $(".queries ." + this.className).toggle();
    return false;
  }
  
  for(var i = 0; i < query_types.length; i++){
    $("#show-hide-all a").click(show_hide_all_queries);
  }
  
  $("#show-hide-all .all").click(function(){$('.queries').toggle(); return false;})
})


jQuery.ajaxSetup({ "beforeSend": function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")} })