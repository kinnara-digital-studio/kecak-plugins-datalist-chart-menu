<!-- Include the FusionChart library file -->
<script defer type="text/javascript" src="${request.contextPath}/plugin/com.kecak.hkm.Dashboard/js/jquery.canvasjs.min.js"></script>
<link rel="stylesheet" type="text/css" href="${request.contextPath}/plugin/com.kecak.hkm.Dashboard/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="${request.contextPath}/plugin/com.kecak.hkm.Dashboard/css/portal.css">
<script>
    function initMap() {
        ${map.content}
    }
    
    $(document).ready(function(){
        
        ${barChart.content}
	
        ${lineChart.content}
    });
</script>
<style>
    .top-buffer { margin-top:20px; }
</style>
<script async defer
    src="https://maps.googleapis.com/maps/api/js?key=AIzaSyDWUpDXe47bJ7f-05ePPzGUNwETUY7x-y4&callback=initMap">
</script>
<div class="dashboard-body-content container-fluid">
        <div class="row">
            <div id="hkm-${map.noSeri}-map" class="col-md-12" style="background-color:#FFFFFF; height:200px;">
            </div>
        </div>
        
        <div class="row top-buffer">
        <h3>INDEX STANDARD PENCEMARAN UDARA - ${map.namaAlat} </h3>
        </div>

        <div class="row top-buffer">
            <div id="wrapper">
                <div class="col-md-3">
                    <div class="span1" style="background-color:#000000;color:#FFFFFF;font-weight:bold;">
                        BERBAHAYA
                    </div>
                    <div class="span1" style="background-color:#FF0000;color:#FFFFFF;font-weight:bold;">
                        SANGAT TIDAK SEHAT
                    </div>
                    <div class="span1" style="background-color:#FFFF00;color:#FFFFFF;font-weight:bold;">
                        TIDAK SEHAT
                    </div>
                    <div class="span1" style="background-color:#0174DF;color:#FFFFFF;font-weight:bold;">
                        SEDANG
                    </div>
                    <div class="span1" style="background-color:#01DF01;color:#FFFFFF;font-weight:bold;">
                        BAIK
                    </div>
                </div>
                <div class="col-md-4">
                    <div id="chartContainer">
                        &nbsp;
                    </div>
                </div>
                <div class="col-md-5">
                    <div id="weeklyContainer">
                        &nbsp;
                    </div>
                </div>
            </div>
        </div>
    
</div>
