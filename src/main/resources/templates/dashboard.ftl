<script type="text/javascript" src="${request.contextPath}/plugin/${className}/bower_components/chart.js/dist/Chart.min.js"></script>
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

		function calculateColor(maxValue, minValue, maxHexColor, minHexColor, value, label) {
			var customColor = _.findWhere(${customColors!}, { "labelValue" : label });

			if(customColor) {
				return hexToRGB(customColor.color);
			} else {
				var percentage = (maxValue == minValue) ? 0 : ((value - minValue) / (maxValue - minValue));
				maxHexColor = maxHexColor.replace(/^#/, '');
				minHexColor = minHexColor.replace(/^#/, '');

				var r = calculateColorComponent(parseInt(maxHexColor.slice(0, 2), 16), parseInt(minHexColor.slice(0, 2), 16), percentage),
			        g = calculateColorComponent(parseInt(maxHexColor.slice(2, 4), 16), parseInt(minHexColor.slice(2, 4), 16), percentage),
			        b = calculateColorComponent(parseInt(maxHexColor.slice(4, 6), 16), parseInt(minHexColor.slice(4, 6), 16), percentage);
				return "rgb(" + r + ", " + g + ", " + b + ")";
			}
		}

		function calculateColorComponent(max, min, percentage) {
			return parseInt(min + percentage * (max - min));
		}

		var arrData = ${data};
		var canvas 	= document.getElementById("dashboard-menu");
		var context = canvas.getContext("2d");
		var chart 	= new Chart(context,
			{
				type : '${element.properties.chartType}',
				data : {
					labels : _.map(arrData, item => item.${element.properties.labelField}),
					datasets : [
						<#assign first = true>
						<#list element.properties.valueFields! as row>
							<#if !first>,</#if>
							{
								label : '${row.field}', <#-- this field was set in java code, not from properties -->
								data : _.map(arrData, item => item.${row.field})
								<#if row.maxColor?? && row.maxColor != ''>
									,
									<#if element.properties.chartType! == 'line' || element.properties.chartType! == 'radar'>
										borderColor	: hexToRGB('${row.maxColor!}'),
										backgroundColor : hexToRGB('${row.maxColor!}', 0.1)
									<#else>
										<#-- backgroundColor : _.map(data, item => hexToRGB('${row.maxColor!}')) -->
										backgroundColor : _.map(arrData, item => calculateColor(
																Math.max(..._.map(arrData, item => item.${row.field})),
																Math.min(..._.map(arrData, item => item.${row.field})),
																'${row.maxColor!}',
																'${row.minColor!}',
																parseFloat(item.${row.field!}),
																item.${element.properties.labelField}))
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

      canvas.onclick = function (evt) {
        var activePoints = chart.getElementsAtEvent(evt);
        var chartData = activePoints[0]['_chart'].config.data;
        var index = activePoints[0]['_index'];

        var parameter = {};
		<#list element.properties.chartAction! as each>
		parameter.${each.chartKey} = arrData[index].${each.chartValue};
		</#list>

        window.open("${element.properties.chartURL}?"+$.param(parameter));
      };
	});
</script>

<canvas id="dashboard-menu" height="${element.properties.height}" width="${element.properties.width}"></canvas>
