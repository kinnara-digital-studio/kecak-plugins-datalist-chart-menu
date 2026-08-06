<script type="text/javascript" src="${request.contextPath}/plugin/${className}/node_modules/chart.js/dist/chart.min.js"></script>
<script type="text/javascript" src="${request.contextPath}/plugin/${className}/node_modules/underscore/underscore-min.js"></script>

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

		let arrData = ${data};
		let canvas 	= document.getElementById("canvas-${element.properties.id!}");
		let context = canvas.getContext("2d");
		let isBullet = '${element.properties.chartType}' === 'bullet';
        if (isBullet) {
            let bulletDataRows = [];
            arrData.forEach(item => {
                let rowObj = { label: item['${element.properties.labelField}'] || 'Unknown' };
                
                <#if element.properties.bulletValueField?? && element.properties.bulletValueField != "">
                    rowObj.actual = parseFloat(item['${element.properties.bulletValueField!}']) || 0;
                </#if>
                
                <#if element.properties.bulletTotalValueField?? && element.properties.bulletTotalValueField != "">
                    rowObj.total = parseFloat(item['${element.properties.bulletTotalValueField!}']) || 0;
                </#if>
                
                bulletDataRows.push(rowObj);
            });

            if (bulletDataRows.length === 0 || !bulletDataRows[0].hasOwnProperty('actual')) {
                bulletDataRows = [
                    { label: "Dummy Data Central", actual: 82000, target: 90000, poor: 50000, sat: 75000, good: 120000 }
                ];
            }

            canvas.style.display = 'none';
            let container = document.createElement('div');
            container.id = 'bullet-container-${element.properties.id!}';
            container.style.width = '${element.properties.width}';
            container.style.marginTop = '20px';
            canvas.parentNode.insertBefore(container, canvas.nextSibling);

            let bulletRanges = [];
            <#if element.properties.bulletRangeColor??>
                <#list element.properties.bulletRangeColor as r>
                    bulletRanges.push({
                        range: '${r.xRange!}',
                        color: '${r.bulletHexColor!}'
                    });
                </#list>
            </#if>
            
            bulletRanges.sort((a, b) => {
                let aVal = parseFloat(a.range) || 0;
                let bVal = parseFloat(b.range) || 0;
                return bVal - aVal;
            });
            
            let globalTargetProp = '${element.properties.target!}';
            let globalTargetNum = parseFloat(globalTargetProp) || 0;
            let isGlobalTargetPct = globalTargetProp.indexOf('%') !== -1;

            let maxVal = 0;
            bulletDataRows.forEach(row => {
                if (row.actual > maxVal) maxVal = row.actual;
                if (row.total !== undefined && row.total > maxVal) maxVal = row.total;
            });
            if (!isGlobalTargetPct && globalTargetNum > maxVal) {
                maxVal = globalTargetNum;
            }
            bulletRanges.forEach(r => {
                if (r.range.indexOf('%') === -1) {
                    let rVal = parseFloat(r.range) || 0;
                    if (rVal > maxVal) maxVal = rVal;
                }
            });
            if (maxVal === 0) maxVal = 1;

            bulletDataRows.forEach(row => {
                let pActual = ((row.actual || 0) / maxVal) * 100;
                let cActual = row.actualColor ? hexToRGB(row.actualColor) : '#666666';

                let pTarget = 0;
                if (row.target !== undefined && row.target > 0) {
                     pTarget = (row.target / maxVal) * 100;
                } else if (globalTargetNum > 0) {
                     if (isGlobalTargetPct) {
                         pTarget = globalTargetNum;
                     } else {
                         pTarget = (globalTargetNum / maxVal) * 100;
                     }
                }
                let cTarget = row.targetColor ? hexToRGB(row.targetColor) : '#333333';
                
                let rangesHtml = '';
                if (bulletRanges.length > 0) {
                    bulletRanges.forEach(r => {
                        let rWidth = 0;
                        if (r.range.indexOf('%') !== -1) {
                            rWidth = parseFloat(r.range) || 0;
                        } else {
                            rWidth = ((parseFloat(r.range) || 0) / maxVal) * 100;
                        }
                        let rColor = r.color ? (hexToRGB(r.color, 1) || r.color) : '#eee';
                        rangesHtml += '<div style="position: absolute; left: 0; top: 0; height: 100%; width: ' + rWidth + '%; background-color: ' + rColor + ';"></div>';
                    });
                } else {
                    let pGood = ((row.good || 0) / maxVal) * 100;
                    let pSat = ((row.sat || 0) / maxVal) * 100;
                    let pPoor = ((row.poor || 0) / maxVal) * 100;
                    let cGood = row.goodColor ? hexToRGB(row.goodColor, 0.4) : 'rgba(204, 255, 204, 0.7)';
                    let cSat = row.satColor ? hexToRGB(row.satColor, 0.4) : 'rgba(255, 255, 204, 0.7)';
                    let cPoor = row.poorColor ? hexToRGB(row.poorColor, 0.4) : 'rgba(255, 204, 204, 0.7)';
                    rangesHtml = '<div style="position: absolute; left: 0; top: 0; height: 100%; width: ' + pGood + '%; background-color: ' + cGood + ';"></div>' +
                                 '<div style="position: absolute; left: 0; top: 0; height: 100%; width: ' + pSat + '%; background-color: ' + cSat + ';"></div>' +
                                 '<div style="position: absolute; left: 0; top: 0; height: 100%; width: ' + pPoor + '%; background-color: ' + cPoor + ';"></div>';
                }

                let rowHtml = <#noparse>`
                    <div style="display: flex; align-items: center; margin-bottom: 25px; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
                        <div style="width: 30%; max-width: 200px; text-align: right; padding-right: 15px;">
                            <div style="font-size: 15px; font-weight: 600; color: #444;">${row.label}</div>
                            <div style="font-size: 11px; color: #888;">Actual vs Target</div>
                        </div>
                        <div style="flex-grow: 1; position: relative; height: 35px; background: #f5f5f5;">
                            <!-- Ranges -->
                            ${rangesHtml}
                            
                            <!-- Actual -->
                            <div style="position: absolute; left: 0; top: 30%; height: 40%; width: ${pActual}%; background-color: ${cActual}; z-index: 1;"></div>
                            
                            <!-- Target -->
                            <div style="position: absolute; left: ${pTarget}%; top: 15%; height: 70%; width: 4px; background-color: ${cTarget}; margin-left: -2px; z-index: 2;"></div>
                        </div>
                        <div style="width: 80px; padding-left: 15px; font-weight: bold; color: #333; font-size: 14px;">
                            ${pActual.toLocaleString(undefined, {maximumFractionDigits: 1})}%
                        </div>
                    </div>
                `</#noparse>;
                container.innerHTML += rowHtml;
            });
            
            let axisLabelsHtml = '';
            let axisTicksHtml = '';
            
            if (bulletRanges.length > 0) {
                axisLabelsHtml += '<div style="position: absolute; left: 0%; transform: translateX(-50%); font-size: 12px; color: #666;">0</div>';
                axisTicksHtml += '<div style="position: absolute; left: 0%; top: 0; height: 5px; width: 2px; background-color: #ccc; margin-top: -5px;"></div>';
                
                bulletRanges.forEach(r => {
                    let rWidth = 0;
                    let labelText = r.range;
                    if (r.range.indexOf('%') !== -1) {
                        rWidth = parseFloat(r.range) || 0;
                    } else {
                        rWidth = ((parseFloat(r.range) || 0) / maxVal) * 100;
                    }
                    
                    axisLabelsHtml += '<div style="position: absolute; left: ' + rWidth + '%; transform: translateX(-50%); font-size: 12px; color: #666;">' + labelText + '</div>';
                    axisTicksHtml += '<div style="position: absolute; left: ' + rWidth + '%; top: 0; height: 5px; width: 2px; background-color: #ccc; margin-top: -5px;"></div>';
                });
            } else {
                let axisLabel0 = 0;
                let axisLabel25 = (maxVal * 0.25).toLocaleString(undefined, {maximumFractionDigits: 1});
                let axisLabel50 = (maxVal * 0.50).toLocaleString(undefined, {maximumFractionDigits: 1});
                let axisLabel75 = (maxVal * 0.75).toLocaleString(undefined, {maximumFractionDigits: 1});
                let axisLabel100 = (maxVal * 1.00).toLocaleString(undefined, {maximumFractionDigits: 1});
                
                axisLabelsHtml += '<div style="position: absolute; left: 0%; transform: translateX(-50%); font-size: 12px; color: #666;">' + axisLabel0 + '</div>';
                axisLabelsHtml += '<div style="position: absolute; left: 25%; transform: translateX(-50%); font-size: 12px; color: #666;">' + axisLabel25 + '</div>';
                axisLabelsHtml += '<div style="position: absolute; left: 50%; transform: translateX(-50%); font-size: 12px; color: #666;">' + axisLabel50 + '</div>';
                axisLabelsHtml += '<div style="position: absolute; left: 75%; transform: translateX(-50%); font-size: 12px; color: #666;">' + axisLabel75 + '</div>';
                axisLabelsHtml += '<div style="position: absolute; left: 100%; transform: translateX(-50%); font-size: 12px; color: #666;">' + axisLabel100 + '</div>';
                
                axisTicksHtml += '<div style="position: absolute; left: 0%; top: 0; height: 5px; width: 2px; background-color: #ccc; margin-top: -5px;"></div>';
                axisTicksHtml += '<div style="position: absolute; left: 25%; top: 0; height: 5px; width: 2px; background-color: #ccc; margin-top: -5px;"></div>';
                axisTicksHtml += '<div style="position: absolute; left: 50%; top: 0; height: 5px; width: 2px; background-color: #ccc; margin-top: -5px;"></div>';
                axisTicksHtml += '<div style="position: absolute; left: 75%; top: 0; height: 5px; width: 2px; background-color: #ccc; margin-top: -5px;"></div>';
                axisTicksHtml += '<div style="position: absolute; left: 100%; top: 0; height: 5px; width: 2px; background-color: #ccc; margin-top: -5px;"></div>';
            }

            let axisHtml = <#noparse>`
                    <div style="display: flex; align-items: center; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
                        <div style="width: 30%; max-width: 200px;"></div>
                        <div style="flex-grow: 1; position: relative; height: 20px; border-top: 2px solid #ccc; padding-top: 5px;">
                            ${axisLabelsHtml}
                            ${axisTicksHtml}
                        </div>
                        <div style="width: 80px;"></div>
                    </div>
            `</#noparse>;
            container.innerHTML += axisHtml;

        } else {
            // ORIGINAL CHART JS INITIALIZATION
            var chart = new Chart(context, {
                type : '${element.properties.chartType}',
                data : {
                    labels : _.map(arrData, item => item.${element.properties.labelField}),
                    datasets : [
                        <#assign first = true>
                        <#list element.properties.valueFields! as row>
                            <#if !first>,</#if>
                            {
                                label : '${row.label}',
                                data : _.map(arrData, item => item.${row.field})
                                <#if row.maxColor?? && row.maxColor != ''>
                                    ,
                                    <#if element.properties.chartType! == 'line' || element.properties.chartType! == 'radar'>
                                        borderColor	: hexToRGB('${row.maxColor!}'),
                                        backgroundColor : hexToRGB('${row.maxColor!}', 0.1)
                                    <#else>
                                        backgroundColor : _.map(arrData, function(item) {
                                                          let sortedDataValues = _.sortBy(arrData, e => -parseFloat(e.${row.field}));
                                                          let index = _.findIndex(sortedDataValues, item, '${element.properties.labelField}');

                                                          return calculateColor(
                                                              arrData.length ? arrData.length - 1 : 0,
                                                              0,
                                                              '${row.maxColor!}',
                                                              '${row.minColor!}',
                                                              index,
                                                              item.${element.properties.labelField});
                                                      })
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
            });

            <#if element.properties.chartURL! != ''>
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
            </#if>
        }
	});
</script>

<div>${customHeader}</div>
<#if showDataListFilter >
    <style>
        .filters { text-align:right; font-size:smaller }
        .filter-cell{display:inline-block;padding-left:5px;}
    </style>

	<form name="filters_${dataListId}" id="filters_${dataListId}" action="?" method="POST">
	    <div class="filters">
	        <#list filterTemplates! as template>
	            <span class="filter-cell">
	                ${template}
	            </span>
	        </#list>
	         <span class="filter-cell">
	             <input type="submit" value="Show"/>
	         </span>
	    </div>
	</form>
</#if>
<canvas id="canvas-${element.properties.id!}" height="${element.properties.height}" width="${element.properties.width}"></canvas>
<div>${customFooter}</div>

