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

        let defs = svg.append("defs");

        let tooltip = d3.select("body").append("div")
            .attr("class", "d3-tooltip");

        let labelField = '${element.properties.labelField}';
        let tooltipField = '${element.properties.tooltipField!}';
        if (!tooltipField) {
            tooltipField = labelField;
        }
        
        let datasets = [];
        <#assign chartFields = "">
        <#if element.properties.barlineLineFields?? && element.properties.barlineLineFields?is_sequence>
            <#assign chartFields = element.properties.barlineLineFields>
        <#elseif element.properties.valueFields?? && element.properties.valueFields?is_sequence>
            <#assign chartFields = element.properties.valueFields>
        </#if>
        
        <#if chartFields?is_sequence>
        <#list chartFields as row>
            <#assign isLineDataset = false>
            <#assign isBarDataset = false>
            <#assign customHexColor = "">
            
            <#if row.barlineType??>
                <#if row.barlineType == 'line'>
                    <#assign isLineDataset = true>
                <#elseif row.barlineType == 'bar'>
                    <#assign isBarDataset = true>
                </#if>
            </#if>
            <#if row.hexColor?? && row.hexColor != ''>
                <#assign customHexColor = row.hexColor>
            </#if>
            
            <#assign useColor = row.maxColor!"">
            <#if customHexColor != "">
                <#assign useColor = customHexColor>
            </#if>
            
            datasets.push({
                field: '${row.field}',
                label: '${row.label}',
                color: '${useColor}',
                isColorField: <#if useColor != "" && !useColor?starts_with("#")>true<#else>false</#if>,
                type: <#if isLineDataset>'line'<#else>'bar'</#if>
            });
        </#list>
        </#if>
        
        let isStacked = '${element.properties.multiBarPosition!}' === 'stack';
        let colorScale = d3.scaleOrdinal(d3.schemeCategory10);

        let customColorsList = <#if customColors?? && customColors?has_content>${customColors}<#else>[]</#if>;
        let customColorsMap = {};
        if (Array.isArray(customColorsList)) {
            customColorsList.forEach(function(c) {
                if (c.labelValue && c.color) {
                    customColorsMap[c.labelValue] = c.color;
                }
            });
        }

        function bindChartClick() {
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
        }

        if (chartType === 'gauge') {
            let gaugeTotalValueField = '${element.properties.gaugeTotalValueField!}';
            let gaugeValueField = '${element.properties.gaugeValueField!}';
            // Use labelField defined globally from element.properties.labelField
            
            let margin = {top: 20, right: 20, bottom: 20, left: 20};
            let innerWidth = width - margin.left - margin.right;
            let innerHeight = height - margin.top - margin.bottom;

            let cols = Math.max(1, Math.ceil(Math.sqrt(arrData.length)));
            let rows = Math.max(1, Math.ceil(arrData.length / cols));
            let cellWidth = innerWidth / cols;
            let cellHeight = innerHeight / rows;
            let radius = Math.min(cellWidth, cellHeight) / 2 * 0.8;
            
            arrData.forEach((d, i) => {
                let col = i % cols;
                let row = Math.floor(i / cols);
                let cx = margin.left + col * cellWidth + cellWidth / 2;
                let cy = margin.top + row * cellHeight + cellHeight / 2 + radius * 0.3;
                
                let gaugeMax = Number(gaugeTotalValueField);
                if (isNaN(gaugeMax) || gaugeMax <= 0) {
                    gaugeMax = Number(d[gaugeTotalValueField]) || 100;
                }
                
                let val = Number(d[gaugeValueField]) || 0;
                let label = d[tooltipField] || '';
                
                let gaugeG = svg.append("g")
                    .attr("class", "d3-element")
                    .attr("transform", "translate(" + cx + ", " + cy + ")")
                    .datum(d)
                    .style("cursor", "pointer")
                    .on("mouseover", function(event, dData) {
                        tooltip.transition().duration(200).style("opacity", .9);
                        tooltip.html("<strong>" + label + "</strong><br/>Value: " + val)
                            .style("left", (event.pageX + 10) + "px")
                            .style("top", (event.pageY - 28) + "px");
                        d3.select(this).attr("opacity", 0.7);
                    })
                    .on("mouseout", function() {
                        tooltip.transition().duration(500).style("opacity", 0);
                        d3.select(this).attr("opacity", 1);
                    });
                
                let arc = d3.arc()
                    .innerRadius(radius * 0.6)
                    .outerRadius(radius)
                    .startAngle(-Math.PI / 2);
                    
                gaugeG.append("path")
                    .datum({endAngle: Math.PI / 2})
                    .style("fill", "#eee")
                    .attr("d", arc);
                    
                let ratio = Math.max(0, Math.min(1, val / gaugeMax));
                let endAngle = -Math.PI / 2 + (ratio * Math.PI);
                
                let arcForeground = d3.arc()
                    .innerRadius(radius * 0.6)
                    .outerRadius(radius)
                    .startAngle(-Math.PI / 2);
                    
                gaugeG.append("path")
                    .datum({endAngle: endAngle})
                    .style("fill", colorScale(i))
                    .attr("d", arcForeground);
                    
                gaugeG.append("text")
                    .attr("text-anchor", "middle")
                    .attr("dy", "-0.1em")
                    .style("font-size", (radius * 0.4) + "px")
                    .style("font-weight", "bold")
                    .style("pointer-events", "none")
                    .text(val);
                    
                if (label) {
                    gaugeG.append("text")
                        .attr("text-anchor", "middle")
                        .attr("dy", (radius * 0.3) + "px")
                        .style("font-size", (radius * 0.15) + "px")
                        .style("pointer-events", "none")
                        .text(label);
                }
            });
            bindChartClick();
        } else {

        datasets.forEach(ds => ds.hidden = false);
        let barDatasetsAll = datasets.filter(ds => ds.type === 'bar');
        let lineDatasetsAll = datasets.filter(ds => ds.type === 'line');

        let isSubLabelMode = false;
        let subLabels = [];
        let hiddenSubLabels = new Set();
        
        if (isStacked && tooltipField && tooltipField !== labelField) {
            let set = new Set();
            arrData.forEach(function(d) {
                let val = d[tooltipField];
                if (val !== undefined && val !== null && String(val).trim() !== '' && !set.has(val)) {
                    set.add(val);
                    subLabels.push(val);
                }
            });
            if (subLabels.length > 0 && barDatasetsAll.length <= 1) {
                isSubLabelMode = true;
            }
        }

        function getSubLabelColor(subLabel, index) {
            if (customColorsMap[subLabel]) {
                return customColorsMap[subLabel];
            }
            if (barDatasetsAll.length > 0) {
                let ds = barDatasetsAll[0];
                let row = arrData.find(function(d) { return d[tooltipField] === subLabel; });
                if (row && ds.isColorField && row[ds.color]) {
                    return row[ds.color];
                }
            }
            return colorScale(index);
        }

        let legendDiv = container.insert("div", "svg")
            .attr("class", "chart-legend")
            .style("display", "flex")
            .style("justify-content", "center")
            .style("margin-bottom", "10px")
            .style("font-family", "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif")
            .style("font-size", "12px")
            .style("flex-wrap", "wrap")
            .style("max-height", "100px")
            .style("overflow-y", "auto")
            .style("padding", "4px 8px");

        if (isSubLabelMode) {
            subLabels.forEach(function(subLabel, idx) {
                let color = getSubLabelColor(subLabel, idx);
                let item = legendDiv.append("div")
                    .style("display", "flex")
                    .style("align-items", "center")
                    .style("margin", "3px 10px")
                    .style("cursor", "pointer")
                    .attr("title", "Click to hide/show " + subLabel)
                    .on("click", function() {
                        if (hiddenSubLabels.has(subLabel)) {
                            hiddenSubLabels.delete(subLabel);
                            d3.select(this).style("opacity", 1);
                            d3.select(this).style("text-decoration", "none");
                        } else {
                            hiddenSubLabels.add(subLabel);
                            d3.select(this).style("opacity", 0.4);
                            d3.select(this).style("text-decoration", "line-through");
                        }
                        drawChart();
                    })
                    .on("mouseenter", function() {
                        if (!hiddenSubLabels.has(subLabel)) {
                            svg.selectAll(".bar").style("opacity", function(d) {
                                return (d[tooltipField] === subLabel ? 1 : 0.25);
                            });
                        }
                    })
                    .on("mouseleave", function() {
                        svg.selectAll(".bar").style("opacity", 1);
                    });

                item.append("div")
                    .style("width", "18px")
                    .style("height", "12px")
                    .style("background-color", color)
                    .style("margin-right", "6px")
                    .style("border-radius", "2px")
                    .style("flex-shrink", "0");

                item.append("span")
                    .style("color", "#444")
                    .text(subLabel);
            });
        } else {
            barDatasetsAll.forEach((ds, i) => {
                let color = ds.color && !ds.isColorField ? ds.color : colorScale(i);
                let item = legendDiv.append("div")
                    .style("display", "flex")
                    .style("align-items", "center")
                    .style("margin", "0 10px")
                    .style("cursor", "pointer")
                    .on("click", function() {
                        ds.hidden = !ds.hidden;
                        d3.select(this).style("opacity", ds.hidden ? 0.5 : 1);
                        d3.select(this).style("text-decoration", ds.hidden ? "line-through" : "none");
                        drawChart();
                    });
                item.append("div")
                    .style("width", "30px")
                    .style("height", "12px")
                    .style("background-color", color)
                    .style("margin-right", "6px");
                item.append("span")
                    .style("color", "#666")
                    .text(ds.label);
            });
        }

        lineDatasetsAll.forEach((ds, i) => {
            let color = ds.color && !ds.isColorField ? ds.color : colorScale(isSubLabelMode ? subLabels.length + i : barDatasetsAll.length + i);
            let item = legendDiv.append("div")
                .style("display", "flex")
                .style("align-items", "center")
                .style("margin", isSubLabelMode ? "3px 10px" : "0 10px")
                .style("cursor", "pointer")
                .on("click", function() {
                    ds.hidden = !ds.hidden;
                    d3.select(this).style("opacity", ds.hidden ? 0.5 : 1);
                    d3.select(this).style("text-decoration", ds.hidden ? "line-through" : "none");
                    drawChart();
                });
            item.append("div")
                .style("width", "30px")
                .style("height", "4px")
                .style("background-color", color)
                .style("margin-right", "6px");
            item.append("span")
                .style("color", "#666")
                .text(ds.label);
        });

        function drawChart() {
            svg.selectAll("*").remove();
            let defs = svg.append("defs");
            
            let activeDatasets = datasets.filter(ds => !ds.hidden);
            let barDatasets = activeDatasets.filter(ds => ds.type === 'bar');
            let lineDatasets = activeDatasets.filter(ds => ds.type === 'line');
            
            let currentArrData = arrData;
            if (isSubLabelMode && hiddenSubLabels.size > 0) {
                currentArrData = arrData.filter(function(d) {
                    return !hiddenSubLabels.has(d[tooltipField]);
                });
            }

            let yMax = 0;
            let yMin = 0;
            
            if (isStacked) {
                let catPos = {};
                let catNeg = {};
                currentArrData.forEach(d => {
                    let cat = d[labelField];
                    if (catPos[cat] === undefined) {
                        catPos[cat] = 0;
                        catNeg[cat] = 0;
                    }
                    barDatasets.forEach(ds => {
                        let v = Number(d[ds.field]) || 0;
                        if (v >= 0) {
                            catPos[cat] += v;
                            d['_posSum_' + ds.field] = catPos[cat];
                        } else {
                            catNeg[cat] += v;
                            d['_negSum_' + ds.field] = catNeg[cat];
                        }
                    });
                });
                for (let cat in catPos) {
                    if (catPos[cat] > yMax) yMax = catPos[cat];
                    if (catNeg[cat] < yMin) yMin = catNeg[cat];
                }
                
                lineDatasets.forEach(ds => {
                    let maxInDs = d3.max(currentArrData, d => Number(d[ds.field]));
                    let minInDs = d3.min(currentArrData, d => Number(d[ds.field]));
                    if (maxInDs > yMax) yMax = maxInDs;
                    if (minInDs < yMin) yMin = minInDs;
                });
            } else {
                activeDatasets.forEach(ds => {
                    let maxInDs = d3.max(currentArrData, d => Number(d[ds.field]));
                    let minInDs = d3.min(currentArrData, d => Number(d[ds.field]));
                    if (maxInDs > yMax) yMax = maxInDs;
                    if (minInDs < yMin) yMin = minInDs;
                });
            }
            if (yMax === 0 && yMin === 0) yMax = 10;

            let isAllInteger = true;
            currentArrData.forEach(d => {
                activeDatasets.forEach(ds => {
                    let raw = d[ds.field];
                    if (raw !== undefined && raw !== null && raw !== '') {
                        let num = Number(raw);
                        if (!isNaN(num) && !Number.isInteger(num)) {
                            isAllInteger = false;
                        }
                    }
                });
            });
            if (!Number.isInteger(yMin) || !Number.isInteger(yMax)) {
                isAllInteger = false;
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
                
            let yDiff = Math.abs(yMax - yMin);
            let y = d3.scaleLinear()
                .range([innerHeight, 0]);

            if (isAllInteger && yDiff > 0 && yDiff <= 10) {
                y.domain([yMin, yMax]);
            } else {
                y.domain([yMin, yMax]).nice();
            }

            let g = svg.append("g")
                .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

            g.append("g")
                .attr("transform", "translate(0," + innerHeight + ")")
                .call(d3.axisBottom(x0))
                .selectAll("text")
                  .attr("transform", "translate(-10,0)rotate(-45)")
                  .style("text-anchor", "end");

            let yAxis = d3.axisLeft(y);
            if (isAllInteger) {
                if (yDiff <= 10) {
                    yAxis.tickValues(d3.range(yMin, yMax + 1));
                } else {
                    yAxis.ticks(Math.min(Math.round(yDiff), 10));
                }
                yAxis.tickFormat(d3.format("d"));
            }

            g.append("g")
                .call(yAxis);

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
                    .data(currentArrData)
                    .enter().append("g")
                    .attr("class", "slice")
                    .attr("transform", d => "translate(" + x0(d[labelField]) + ",0)");
    
                barDatasets.forEach((ds) => {
                    let i = barDatasetsAll.indexOf(ds);
                    slice.append("rect")
                        .attr("class", "bar d3-element")
                        .attr("x", isStacked ? 0 : x1(ds.field))
                        .attr("y", d => {
                            let val = Number(d[ds.field]);
                            if (isStacked) {
                                if (val >= 0) {
                                    return y(d['_posSum_' + ds.field]);
                                } else {
                                    return y(d['_negSum_' + ds.field] - val);
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
                                    let currentPos = d['_posSum_' + ds.field];
                                    return Math.abs(y(currentPos - val) - y(currentPos));
                                } else {
                                    let currentNeg = d['_negSum_' + ds.field];
                                    return Math.abs(y(currentNeg - val) - y(currentNeg));
                                }
                            } else {
                                return Math.abs(y(val) - y(0));
                            }
                        })
                        .attr("fill", d => {
                            if (isSubLabelMode) {
                                let subLabel = d[tooltipField];
                                let idx = subLabels.indexOf(subLabel);
                                return getSubLabelColor(subLabel, idx >= 0 ? idx : 0);
                            }
                            if (ds.isColorField && d[ds.color]) return d[ds.color];
                            return ds.color && !ds.isColorField ? ds.color : colorScale(i);
                        })
                        .on("mouseover", function(event, d) {
                            tooltip.transition().duration(200).style("opacity", .9);
                            tooltip.html("<strong>" + (d[tooltipField] || d[labelField]) + "</strong><br/>" + ds.label + ": " + d[ds.field])
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
                lineDatasets.forEach((ds) => {
                    let i = barDatasetsAll.length + lineDatasetsAll.indexOf(ds);
                    let line = d3.line()
                        .x(d => x0(d[labelField]) + x0.bandwidth() / 2)
                        .y(d => y(Number(d[ds.field])));
                        
                    let pathColor;
                    if (ds.isColorField) {
                        let gradientId = "line-gradient-" + ds.field + "-" + Math.floor(Math.random() * 10000);
                        let gradient = defs.append("linearGradient")
                            .attr("id", gradientId)
                            .attr("gradientUnits", "userSpaceOnUse")
                            .attr("x1", 0)
                            .attr("y1", 0)
                            .attr("x2", innerWidth)
                            .attr("y2", 0);
                            
                        currentArrData.forEach(d => {
                            let xPos = x0(d[labelField]) + x0.bandwidth() / 2;
                            let offset = xPos / innerWidth;
                            gradient.append("stop")
                                .attr("offset", (offset * 100) + "%")
                                .attr("stop-color", d[ds.color] ? d[ds.color] : colorScale(barDatasets.length + i));
                        });
                        
                        pathColor = "url(#" + gradientId + ")";
                    } else {
                        pathColor = ds.color ? ds.color : colorScale(barDatasets.length + i);
                    }
                    
                    g.append("path")
                        .datum(currentArrData)
                        .attr("fill", "none")
                        .attr("stroke", pathColor)
                        .attr("stroke-width", 3)
                        .attr("d", line);
                        
                    g.selectAll(".dot-" + ds.field)
                        .data(currentArrData)
                        .enter().append("circle")
                        .attr("class", "dot d3-element")
                        .attr("cx", d => x0(d[labelField]) + x0.bandwidth() / 2)
                        .attr("cy", d => y(Number(d[ds.field])))
                        .attr("r", 5)
                        .attr("fill", d => {
                            if (ds.isColorField && d[ds.color]) return d[ds.color];
                            return ds.color && !ds.isColorField ? ds.color : colorScale(barDatasets.length + i);
                        })
                        .on("mouseover", function(event, d) {
                            tooltip.transition().duration(200).style("opacity", .9);
                            tooltip.html("<strong>" + (d[tooltipField] || d[labelField]) + "</strong><br/>" + ds.label + ": " + d[ds.field])
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
             bindChartClick();
        }
        drawChart();
        }
    });
</script>
