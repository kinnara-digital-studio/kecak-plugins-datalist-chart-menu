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
        <#assign lineFieldsClean = "," + (element.properties.barlineLineFields!"")?replace(" ", "") + ",">
        <#list element.properties.valueFields! as row>
            <#assign isLineDataset = (element.properties.chartType! == 'barline' && lineFieldsClean?contains("," + row.field + ","))>
            datasets.push({
                field: '${row.field}',
                label: '${row.label}',
                color: '${row.maxColor!}',
                type: <#if isLineDataset>'line'<#else>'bar'</#if>
            });
        </#list>
        
        let yMax = 0;
        datasets.forEach(ds => {
            let maxInDs = d3.max(arrData, d => Number(d[ds.field]));
            if (maxInDs > yMax) yMax = maxInDs;
        });
        if (yMax === 0) yMax = 10;
        
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
                .domain([0, yMax]);

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
                        .attr("x", x1(ds.field))
                        .attr("y", d => y(Number(d[ds.field])))
                        .attr("width", x1.bandwidth())
                        .attr("height", d => innerHeight - y(Number(d[ds.field])))
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
                 .domain([0, yMax]);

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
