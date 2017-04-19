<script src="https://d3js.org/d3.v4.min.js"></script>
<script type="text/javascript" src="${request.contextPath}/plugin/${className}/bower_components/chart.js/dist/Chart.js"></script>
<script type="text/javascript" src="${request.contextPath}/plugin/${className}/bower_components/underscore/underscore-min.js"></script>

<script>
	
	$('document').ready(function() {
		function hexToRGB(hex, alpha) {
			hex = hex.replace(/^#/, '');
		    var r = parseInt(hex.slice(0, 2), 16),
		        g = parseInt(hex.slice(2, 4), 16),
		        b = parseInt(hex.slice(4, 6), 16);
		
		    if (alpha) {
		        return "rgba(" + r + ", " + g + ", " + b + ", " + alpha + ")";
		    } else {
		        return "rgb(" + r + ", " + g + ", " + b + ")";
		    }
		}
		
		function calculateColor(maxValue, minValue, maxHexColor, minHexColor, value) {
			var percentage = (maxValue == minValue) ? 0 : ((value - minValue) / (maxValue - minValue));
			maxHexColor = maxHexColor.replace(/^#/, '');
			minHexColor = minHexColor.replace(/^#/, '');
			
			var r = calculateColorComponent(parseInt(maxHexColor.slice(0, 2), 16), parseInt(minHexColor.slice(0, 2), 16), percentage),
		        g = calculateColorComponent(parseInt(maxHexColor.slice(2, 4), 16), parseInt(minHexColor.slice(2, 4), 16), percentage),
		        b = calculateColorComponent(parseInt(maxHexColor.slice(4, 6), 16), parseInt(minHexColor.slice(4, 6), 16), percentage);
			return "rgb(" + r + ", " + g + ", " + b + ")"; 			
		}
		
		function calculateColorComponent(max, min, percentage) {
			return parseInt(min + percentage * (max - min));
		}
		
		var arrData = ${data};
		
		var chart = new Chart(
			$("canvas#dashboard-menu"),
			{
				type : '${element.properties.chartType}',
				data : {
					labels : _.map(arrData, item => item.${element.properties.labelField}),
					datasets : [
						<#assign first = true>
						<#list element.properties.valueFields! as row>
							<#if !first>,</#if>
							{
								label : '${row.field}',
								data : _.map(arrData, item => item.${row.field})
								<#if row.maxColor?? && row.maxColor != ''>
									,
									<#if element.properties.chartType! == 'line'>
										borderColor	: _.map(arrData, item => hexToRGB('${row.maxColor!}'))
									<#else>
										<#-- backgroundColor : _.map(data, item => hexToRGB('${row.maxColor!}')) -->
										backgroundColor : _.map(arrData, item => calculateColor(
																Math.max(..._.map(arrData, item => item.${row.field})),
																Math.min(..._.map(arrData, item => item.${row.field})),
																'${row.maxColor!}',
																'${row.minColor!}',
																parseFloat(item.${row.field!})))
									</#if>
								</#if>
							}
							
							<#assign first = false>
						</#list>
					]
				},
				options: {
					<#if element.properties.chartType! == 'bar' || element.properties.chartType! == 'line'>
	        			scales: {
	        				yAxes: [{
	                			ticks: {
	                    			beginAtZero:true
	                			}
	            			}]
	        			}
	        		</#if>
    			}
			}
		);
	});
</script>

<canvas id="dashboard-menu" height="100%" width="100%"></canvas>
