<script type="text/javascript" src="${request.contextPath}/plugin/${className}/node_modules/d3/dist/d3.min.js"></script>
<script type="text/javascript" src="${request.contextPath}/plugin/${className}/node_modules/underscore/underscore-min.js"></script>

<style>
.d3-tooltip {
    position: absolute;
    text-align: center;
    padding: 8px;
    font: 12px sans-serif;
    background: white;
    border: 1px solid #aaa;
    border-radius: 4px;
    pointer-events: none;
    opacity: 0;
    box-shadow: 0px 0px 5px rgba(0,0,0,0.3);
}
</style>

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

<div id="d3-container-${element.properties.id!}" style="width: ${element.properties.width}; height: ${element.properties.height}; position: relative; min-height: 400px;"></div>

<div>${customFooter}</div>

<script>
    $('document').ready(function() {
        let arrData = ${data};
        let chartType = '${element.properties.chartType!}';
        let containerId = "#d3-container-${element.properties.id!}";
        let container = d3.select(containerId);
        
        let width = $(containerId).width() || 600;
        let height = $(containerId).height() || 400;
        if(height < 100) height = 400; 
        
        container.selectAll("*").remove(); 
        
        let svg = container.append("svg")
            .attr("width", width)
            .attr("height", height);

        let tooltip = d3.select("body").append("div")
            .attr("class", "d3-tooltip");

        let labelField = '${element.properties.labelField}';
        
        let datasets = [];
        <#list element.properties.valueFields! as row>
            <#assign isLineDataset = false>
            <#assign isBarDataset = false>
            <#assign customHexColor = "">
            
            <#if element.properties.chartType! == 'barline'>
                <#if element.properties.barlineLineFields?? && element.properties.barlineLineFields?is_sequence>
                    <#list element.properties.barlineLineFields as blf>
                        <#if blf.field == row.field>
                            <#if blf.barlineType! == 'line'>
                                <#assign isLineDataset = true>
                            <#elseif blf.barlineType! == 'bar'>
                                <#assign isBarDataset = true>
                            </#if>
                            <#if blf.hexColor?? && blf.hexColor != ''>
                                <#assign customHexColor = blf.hexColor>
                            </#if>
                        </#if>
                    </#list>
                </#if>
            </#if>
            
            <#assign useColor = row.maxColor!"">
            <#if customHexColor != "">
                <#assign useColor = customHexColor>
            </#if>
            
            datasets.push({
                field: '${row.field}',
                label: '${row.label}',
                color: '${useColor}',
                type: <#if isLineDataset>'line'<#else>'bar'</#if>
            });
        </#list>
        
        let yMax = 0;
        let yMin = 0;
        let isStacked = '${element.properties.multiBarPosition!}' === 'stack' && (chartType === 'bar' || chartType === 'barline');
        
        if (isStacked) {
            let barDatasetsLocal = datasets.filter(ds => ds.type === 'bar');
            arrData.forEach(d => {
                let pos = 0;
                let neg = 0;
                barDatasetsLocal.forEach(ds => {
                    let v = Number(d[ds.field]) || 0;
                    if (v >= 0) pos += v;
                    else neg += v;
                });
                if (pos > yMax) yMax = pos;
                if (neg < yMin) yMin = neg;
                
                d._posSum = 0;
                d._negSum = 0;
            });
            datasets.filter(ds => ds.type === 'line').forEach(ds => {
                let maxInDs = d3.max(arrData, d => Number(d[ds.field]));
                let minInDs = d3.min(arrData, d => Number(d[ds.field]));
                if (maxInDs > yMax) yMax = maxInDs;
                if (minInDs < yMin) yMin = minInDs;
            });
        } else {
            datasets.forEach(ds => {
                let maxInDs = d3.max(arrData, d => Number(d[ds.field]));
                let minInDs = d3.min(arrData, d => Number(d[ds.field]));
                if (maxInDs > yMax) yMax = maxInDs;
                if (minInDs < yMin) yMin = minInDs;
            });
        }
        if (yMax === 0 && yMin === 0) yMax = 10;
        
        let colorScale = d3.scaleOrdinal(d3.schemeCategory10);

        if (chartType === 'bar' || chartType === 'barline') {
            let barDatasets = datasets.filter(ds => ds.type === 'bar');
            let lineDatasets = datasets.filter(ds => ds.type === 'line');
            if (chartType === 'bar') {
                barDatasets = datasets; // for 'bar', all datasets are bars
                lineDatasets = [];
            }
        
            let margin = {top: 30, right: 30, bottom: 50, left: 50};
            let innerWidth = width - margin.left - margin.right;
            let innerHeight = height - margin.top - margin.bottom;

            let x0 = d3.scaleBand()
                .range([0, innerWidth])
                .padding(0.2)
                .domain(arrData.map(d => d[labelField]));
                
            let x1 = d3.scaleBand()
                .domain(barDatasets.map(ds => ds.field))
                .range([0, x0.bandwidth()])
                .padding(0.05);
                
            let y = d3.scaleLinear()
                .range([innerHeight, 0])
                .domain([yMin, yMax]).nice();

            let g = svg.append("g")
                .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

            g.append("g")
                .attr("transform", "translate(0," + innerHeight + ")")
                .call(d3.axisBottom(x0))
                .selectAll("text")
                  .attr("transform", "translate(-10,0)rotate(-45)")
                  .style("text-anchor", "end");

            g.append("g")
                .call(d3.axisLeft(y));

            if (yMin < 0) {
                g.append("line")
                    .attr("x1", 0)
                    .attr("x2", innerWidth)
                    .attr("y1", y(0))
                    .attr("y2", y(0))
                    .attr("stroke", "#000")
                    .attr("stroke-width", 1);
            }

            // Draw bars
            if (barDatasets.length > 0) {
                let slice = g.selectAll(".slice")
                    .data(arrData)
                    .enter().append("g")
                    .attr("class", "slice")
                    .attr("transform", d => "translate(" + x0(d[labelField]) + ",0)");
    
                barDatasets.forEach((ds, i) => {
                    slice.append("rect")
                        .attr("class", "bar d3-element")
                        .attr("x", isStacked ? 0 : x1(ds.field))
                        .attr("y", d => {
                            let val = Number(d[ds.field]);
                            if (isStacked) {
                                if (val >= 0) {
                                    d._posSum += val;
                                    return y(d._posSum);
                                } else {
                                    let prev = d._negSum;
                                    d._negSum += val;
                                    return y(prev);
                                }
                            } else {
                                return val >= 0 ? y(val) : y(0);
                            }
                        })
                        .attr("width", isStacked ? x0.bandwidth() : x1.bandwidth())
                        .attr("height", d => {
                            let val = Number(d[ds.field]);
                            if (isStacked) {
                                if (val >= 0) {
                                    return Math.abs(y(d._posSum - val) - y(d._posSum));
                                } else {
                                    return Math.abs(y(d._negSum) - y(d._negSum - val));
                                }
                            } else {
                                return Math.abs(y(val) - y(0));
                            }
                        })
                        .attr("fill", ds.color ? ds.color : colorScale(i))
                        .on("mouseover", function(event, d) {
                            tooltip.transition().duration(200).style("opacity", .9);
                            tooltip.html("<strong>" + d[labelField] + "</strong><br/>" + ds.label + ": " + d[ds.field])
                                .style("left", (event.pageX + 10) + "px")
                                .style("top", (event.pageY - 28) + "px");
                            d3.select(this).attr("opacity", 0.7);
                        })
                        .on("mouseout", function(d) {
                            tooltip.transition().duration(500).style("opacity", 0);
                            d3.select(this).attr("opacity", 1);
                        });
                });
            }
            
            // Draw lines
            if (lineDatasets.length > 0) {
                lineDatasets.forEach((ds, i) => {
                    let line = d3.line()
                        .x(d => x0(d[labelField]) + x0.bandwidth() / 2)
                        .y(d => y(Number(d[ds.field])));
                        
                    g.append("path")
                        .datum(arrData)
                        .attr("fill", "none")
                        .attr("stroke", ds.color ? ds.color : colorScale(barDatasets.length + i))
                        .attr("stroke-width", 3)
                        .attr("d", line);
                        
                    g.selectAll(".dot-" + ds.field)
                        .data(arrData)
                        .enter().append("circle")
                        .attr("class", "dot d3-element")
                        .attr("cx", d => x0(d[labelField]) + x0.bandwidth() / 2)
                        .attr("cy", d => y(Number(d[ds.field])))
                        .attr("r", 5)
                        .attr("fill", ds.color ? ds.color : colorScale(barDatasets.length + i))
                        .on("mouseover", function(event, d) {
                            tooltip.transition().duration(200).style("opacity", .9);
                            tooltip.html("<strong>" + d[labelField] + "</strong><br/>" + ds.label + ": " + d[ds.field])
                                .style("left", (event.pageX + 10) + "px")
                                .style("top", (event.pageY - 28) + "px");
                            d3.select(this).attr("r", 7);
                        })
                        .on("mouseout", function(d) {
                            tooltip.transition().duration(500).style("opacity", 0);
                            d3.select(this).attr("r", 5);
                        });
                });
            }
        } else if (chartType === 'pie' || chartType === 'doughnut') {
            let ds = datasets[0]; // For pie/doughnut we usually only show the first dataset
            if (!ds) ds = { field: 'value', label: 'Value', color: null };
            
            let radius = Math.min(width, height) / 2 - 20;
            let innerRadius = chartType === 'doughnut' ? radius * 0.5 : 0;
            
            let g = svg.append("g")
                .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
                
            let pie = d3.pie()
                .value(d => Number(d[ds.field]))
                .sort(null);
                
            let path = d3.arc()
                .outerRadius(radius)
                .innerRadius(innerRadius);
                
            let arc = g.selectAll(".arc")
                .data(pie(arrData))
                .enter().append("g")
                .attr("class", "arc d3-element");
                
            arc.append("path")
                .attr("d", path)
                .attr("fill", (d, i) => ds.color ? d3.color(ds.color).darker(i/arrData.length) : colorScale(i))
                .on("mouseover", function(event, d) {
                    tooltip.transition().duration(200).style("opacity", .9);
                    tooltip.html("<strong>" + d.data[labelField] + "</strong><br/>" + ds.label + ": " + d.data[ds.field])
                        .style("left", (event.pageX + 10) + "px")
                        .style("top", (event.pageY - 28) + "px");
                    d3.select(this).attr("opacity", 0.7);
                })
                .on("mouseout", function(d) {
                    tooltip.transition().duration(500).style("opacity", 0);
                    d3.select(this).attr("opacity", 1);
                });
                
            if (chartType === 'doughnut') {
                let total = d3.sum(arrData, d => Number(d[ds.field]));
                g.append("text")
                    .attr("text-anchor", "middle")
                    .attr("dy", ".3em")
                    .style("font-size", "24px")
                    .style("font-weight", "bold")
                    .style("font-family", "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif")
                    .text(total);
            }
        } else if (chartType === 'line') {
             let margin = {top: 30, right: 30, bottom: 50, left: 50};
             let innerWidth = width - margin.left - margin.right;
             let innerHeight = height - margin.top - margin.bottom;

             let x = d3.scalePoint()
                 .range([0, innerWidth])
                 .padding(0.5)
                 .domain(arrData.map(d => d[labelField]));
                 
             let y = d3.scaleLinear()
                 .range([innerHeight, 0])
                 .domain([yMin, yMax]).nice();

             let g = svg.append("g")
                 .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

             g.append("g")
                 .attr("transform", "translate(0," + innerHeight + ")")
                 .call(d3.axisBottom(x))
                 .selectAll("text")
                  .attr("transform", "translate(-10,0)rotate(-45)")
                  .style("text-anchor", "end");

             g.append("g")
                 .call(d3.axisLeft(y));

             if (yMin < 0) {
                 g.append("line")
                     .attr("x1", 0)
                     .attr("x2", innerWidth)
                     .attr("y1", y(0))
                     .attr("y2", y(0))
                     .attr("stroke", "#000")
                     .attr("stroke-width", 1);
             }

             datasets.forEach((ds, i) => {
                 let line = d3.line()
                     .x(d => x(d[labelField]))
                     .y(d => y(Number(d[ds.field])));
    
                 g.append("path")
                     .datum(arrData)
                     .attr("fill", "none")
                     .attr("stroke", ds.color ? ds.color : colorScale(i))
                     .attr("stroke-width", 3)
                     .attr("d", line);
                     
                 g.selectAll(".dot-" + ds.field)
                     .data(arrData)
                     .enter().append("circle")
                     .attr("class", "dot d3-element")
                     .attr("cx", d => x(d[labelField]))
                     .attr("cy", d => y(Number(d[ds.field])))
                     .attr("r", 5)
                     .attr("fill", ds.color ? ds.color : colorScale(i))
                     .on("mouseover", function(event, d) {
                         tooltip.transition().duration(200).style("opacity", .9);
                         tooltip.html("<strong>" + d[labelField] + "</strong><br/>" + ds.label + ": " + d[ds.field])
                             .style("left", (event.pageX + 10) + "px")
                             .style("top", (event.pageY - 28) + "px");
                         d3.select(this).attr("r", 7);
                     })
                     .on("mouseout", function(d) {
                         tooltip.transition().duration(500).style("opacity", 0);
                         d3.select(this).attr("r", 5);
                     });
             });
        } else if (chartType === 'bullet') {
            svg.remove();

            function hexToRGB(hex, alpha) {
                if (!hex) return '';
                hex = hex.replace(/^#/, '');
                if (hex.length === 3) hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2];
                var r = parseInt(hex.slice(0, 2), 16) || 0,
                    g = parseInt(hex.slice(2, 4), 16) || 0,
                    b = parseInt(hex.slice(4, 6), 16) || 0;
                if (alpha) {
                    return "rgba(" + r + ", " + g + ", " + b + ", " + alpha + ")";
                } else {
                    return "rgb(" + r + ", " + g + ", " + b + ")";
                }
            }

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

            let domContainer = document.querySelector(containerId);
            domContainer.style.width = '${element.properties.width}';
            domContainer.style.marginTop = '20px';

            if (bulletDataRows.length === 0 || !bulletDataRows[0].hasOwnProperty('actual')) {
                domContainer.style.textAlign = 'center';
                domContainer.style.padding = '30px';
                domContainer.style.color = '#888';
                domContainer.style.fontFamily = "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif";
                domContainer.style.fontStyle = 'italic';
                domContainer.innerHTML = 'Nothing found to display';
            } else {
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

                let hasPctRanges = bulletRanges.length > 0 && bulletRanges.some(r => r.range.indexOf('%') !== -1);

                bulletDataRows.forEach(row => {
                    let rowMax = maxVal;
                    if (hasPctRanges) {
                        if (row.total !== undefined && row.total > 0) {
                            rowMax = row.total;
                        } else if (globalTargetNum > 0 && !isGlobalTargetPct) {
                            rowMax = globalTargetNum;
                        }
                    }

                    let pActual = ((row.actual || 0) / rowMax) * 100;
                    let cActual = row.actualColor ? hexToRGB(row.actualColor) : '#666666';

                    let pTarget = 0;
                    if (globalTargetNum > 0) {
                         if (isGlobalTargetPct) {
                             pTarget = globalTargetNum;
                         } else {
                             pTarget = (globalTargetNum / rowMax) * 100;
                         }
                    } else if (row.total !== undefined && row.total > 0) {
                         pTarget = (row.total / rowMax) * 100;
                    }
                    let cTarget = row.targetColor ? hexToRGB(row.targetColor) : '#333333';

                    let displayPct = pActual;
                    if (!hasPctRanges && row.total !== undefined && row.total > 0) {
                        displayPct = ((row.actual || 0) / row.total) * 100;
                    }
                    
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
                                ${displayPct.toLocaleString(undefined, {maximumFractionDigits: 1})}%
                            </div>
                        </div>
                    `</#noparse>;
                    domContainer.innerHTML += rowHtml;
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
                domContainer.innerHTML += axisHtml;
            }
        } else {
            container.append("div")
                .style("padding", "30px")
                .style("text-align", "center")
                .style("color", "#888")
                .text("Chart type '" + chartType + "' is not yet fully implemented in this D3 JS template.");
        }
        
        <#if element.properties.chartURL! != ''>
        svg.selectAll(".d3-element").on("click", function(event, d) {
            let dataObj = d.data ? d.data : d;
            let parameter = {};
            <#list element.properties.chartAction! as each>
                parameter["${each.chartKey}"] = dataObj["${each.chartValue}"];
            </#list>
            window.open("${element.properties.chartURL}?" + $.param(parameter));
        });
        </#if>
    });
</script>
