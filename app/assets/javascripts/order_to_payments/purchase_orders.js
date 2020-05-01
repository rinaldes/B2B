$(document).ready(function() {
  // Setup - add a text input to each footer cell
  $('#results tfoot th').each(function() {
    var title = $(this).text();
    $(this).html('<input type="text" placeholder="Search ' + title + '" />');
  });

  // DataTable
  var table = $('#results').DataTable({
    "aoColumnDefs": [
      { "bSortable": false, "aTargets": [ 6 ] }
    ],
    "aaSorting": [] });

  $('#results tfoot th').each(function(i) {
    var title = $('#results thead th').eq($(this).index()).text();
    // or just var title = $('#sample_3 thead th').text();
    var serach = '<input type="text" placeholder="Search ' + title + '" />';
    $(this).html('');
    $(serach).appendTo(this).keyup(function() {
      table.fnFilter($(this).val(), i)
    })
  });
});
