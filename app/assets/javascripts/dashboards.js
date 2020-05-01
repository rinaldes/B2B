function get_stats_for(el, graph_id) {
  var id = el.id;
  $("#" + id).bind('ajax:beforeSend', function() {
    ajax_loading_graph("graph-purchase-orders");
  }).bind('ajax:success', function(data, status, xhr, request) {
    $("#insert-before-ajax-loading").remove();
    var data = json_for_plot_js(request.responseText);
    var po_type = decodeURI($("#" + id).attr("href")).split("/")[3];
    var str_for_tooltip = "Total " + po_type + " with status %s on %x are %y";
    var nana = create_flot("graph-purchase-orders", data, str_for_tooltip);
    $("#order-type-po-stats").val("" + po_type);
    $("#graph-purchase-orders").bind("plotclick", function(event, pos, item) {
      if (item) {
        $.ajax({
          beforeSend: function(request) {},
          success: function(request) {
            jQuery('#page-content').html(request)
          },
          error: function(request) {},
          complete: function(request) {},
          url: ""
        });
      }
    });
    $("#select-po-stats").trigger("click");
    return false
  }).bind('ajax:error', function(data, status, xhr, request) {
    return false;
  });
}

function load_graph(id, path, type) {
  var date = $("#datepicker").val().replace("-", "");
  if (date == "") {
    var d = new Date();
    var year = d.getFullYear();
    var month = d.getMonth() + 1;

    date = year + "" + (month < 10 ? "0": "") + month;
  }

  $.ajax({
    beforeSend: function(request) {
      ajax_loading_graph("graph-purchase-orders");
    },
    success: function(request) {
      $("#insert-before-ajax-loading").remove();
      var data = request;
      var po_type = type;
      var str_for_tooltip = "Total " + po_type + " with status %s on %x are %y";
      var nana = create_flot(id, data, str_for_tooltip, type);

      $("#order-type-po-stats").val("" + po_type);
      $("#" + id).bind("plotclick", function(event, pos, item) {
        if (item) {
          var state = item.series.label.toString();
          var type = $("#select-order-type option:selected").val().toLowerCase().split(" ").join("_");
          var url = "";
          var date = new Date(item.datapoint[0]);
          var from = "" + date.getDate() + "/" + parseInt(date.getMonth() + 1) + "/" + date.getFullYear();
          var date2 = new Date(date.getFullYear(), date.getMonth() + 1, 0);
          var to = "" + date2.getDate() + "/" + parseInt(date2.getMonth() + 1) + "/" + date2.getFullYear();

          // SET URI UNTUK SETIAP LINK DI CHART DASHBOARD
          if (type == "goods_return_note") {
            type = "goods_return_note"
          } else {
            if (type == "purchase_order") {
              type = "purchase_orders"
            } else if (type == "invoice") {
              type = "invoices"
            } else if (type == "goods_receive_notes") {
              type = "goods_receive_notes"
            } else if (type == "report_goods_receive_price_confirmations") {
              type = "goods_receive_price_confirmations"
            }
            //url = "order_to_payments/"+type;
          }

          url = "dashboards/get_report?type=" + type

          $('#form_stats_dashboard #search_period_1').val(from);
          $('#form_stats_dashboard #search_period_2').val(to);
          $('#form_stats_dashboard #search_field').val("Status");
          $('#form_stats_dashboard #search_detail').val(state);
          $('#form_stats_dashboard #search_order_type').val(type);
          $('#form_stats_dashboard').attr('action', url).submit();
        }
      });
      $("#select-po-stats").trigger("click");
      return false
    },
    error: function(request) {},
    complete: function(request) {},
    url: "dashboards/" + path + "/" + type + "/" + date + ""
  });
}

function get_po_stats_by(el) {
  load_graph("graph-purchase-orders1", "report_purchase_order", "Purchase Order");
  load_graph("graph-purchase-orders2", "report_goods_receive_notes", "Goods Receive Notes");
  load_graph("graph-purchase-orders3", "report_goods_receive_price_confirmations", "Goods Receive Price Confirmations");
  load_graph("graph-purchase-orders4", "report_invoice", "Invoice");
  load_graph("graph-purchase-orders6", "report_debit_note", "Debit Notes");
}

function get_count_disputed_po() {
  $(document).ready(function() {
    $.ajax({
      beforeSend: function(request) {},
      success: function(request) {
        $("#tab-grtn span").addClass("icon-only icon-animated-vertical")
        $("#tab-grtn span").text(request.disp_grtn);
      },
      error: function(request) {},
      complete: function(request) {},
      url: "dashboards/get_po_today_status"
    });
  });
}

function get_count_disputed_dn() {
  $(document).ready(function() {
    $.ajax({
      beforeSend: function(request) {},
      success: function(request) {
        if (request.disp_gns > 0) {
          $("#tab-dn span").addClass("icon-only icon-animated-vertical")
          $("#tab-dn span").text(request.disp_grtn);
        }
      },
      error: function(request) {},
      complete: function(request) {},
      url: "dashboards/count_disputed_dn"
    });
  });
}


function get_service_level_by_supplier(id, type, path) {
  if (type == "wh") {
    get_suppliers(id, path);
  } else {
    get_graph_ss(id, path)
  }
}

function get_graph_ss(id, path) {
  if (id.length === 0) {
    id = "no-supplier"
  }

  $.ajax({
    url: path + id,
    success: function(request) {
      create_graph(request.sl_stats, request.year)
    }
  })
}

// list supplier based on group supplier or warehouse
function get_suppliers(id, path) {
  $.ajax({
    url: path + "?id=" + id,
    success: function(request) {
      $(".sp_select_supp").html(request)
    }
  })
}

function create_graph(sl_stats, year) {
  $(function() {
    var sl = sl_stats;
    var d1 = [];
    var y = 0;
    var current_year = year;
    d1 = sl;

    if ($("#select_supplier option:selected").text() == "no-supplier") {
      var supplier_name = "No-Supplier";
    } else {
      var supplier_name = $("#select_supplier option:selected").text();
    }

    var graph = $('#graph').css({
      'width': '100%',
      'height': '420px'
    });
    var somePlot = $.plot("#graph", [{
      label: "Service Level",
      data: d1
    }], {
      hoverable: true,
      shadowSize: 0,
      series: {
        lines: {
          show: true
        },
        points: {
          show: true
        }
      },
      xaxis: {
        min: (new Date(current_year, 0, 1)).getTime(),
        max: (new Date(current_year, 11, 31)).getTime(),
        mode: "time",
        TickSize: [1, "month"]
      },
      yaxis: {
        ticks: 10,
        min: 0,
        max: 100,
        tickDecimals: 0
      },
      grid: {
        backgroundColor: {
          colors: ["#fff", "#fff"]
        },
        borderWidth: 1,
        borderColor: '#555',
        hoverable: true
      },
      legend: {
        show: true,
        container: '#graph-legend'
      },
      tooltip: true,
      tooltipOpts: {
        content: function(label, xval, yval) {
          var content = "%s supplier " + supplier_name + " on %x is " + yval + "%";
          return content;
        },
        shifts: {
          x: -60,
          y: 25
        }
      }
    });
  })
}
