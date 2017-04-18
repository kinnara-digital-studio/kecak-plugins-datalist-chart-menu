<script src="https://d3js.org/d3.v4.min.js"></script>
<script type="text/javascript" src="${request.contextPath}/plugin/${className}/bower_components/chart.js/dist/Chart.js"></script>
<script type="text/javascript" src="${request.contextPath}/plugin/${className}/bower_components/underscore/underscore-min.js"></script>

<script>
	
	$('document').ready(function() {
		var data = ${data};
		
		var chart = new Chart(
			$("canvas#dashboard-menu"),
			{
				type : '${element.properties.chartType}',
				data : {
					labels : _.map(data, item => item.${element.properties.labelField}),
					datasets : [{
						label : '${element.properties.valueField}',
						data : _.map(data, item => item.${element.properties.valueField})
					}]
				},
				options: {
        			scales: {
            			yAxes: [{
                			ticks: {
                    			beginAtZero:true
                			}
            			}]
        			}
    			}
			}
		);
	});
</script>

<canvas id="dashboard-menu" height="100%" width="100%"></canvas>
