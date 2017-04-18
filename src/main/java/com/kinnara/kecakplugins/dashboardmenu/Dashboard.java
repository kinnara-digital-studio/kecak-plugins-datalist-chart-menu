/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.kecak.hkm;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Collection;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.Map;
import javax.sql.DataSource;
import org.joget.apps.app.model.AppDefinition;
import org.joget.apps.app.service.AppUtil;
import org.joget.apps.userview.model.UserviewMenu;
import org.joget.commons.util.LogUtil;
import org.joget.directory.model.Group;
import org.joget.directory.model.service.DirectoryManager;
import org.joget.plugin.base.PluginManager;
import org.joget.workflow.model.service.WorkflowUserManager;
import org.springframework.context.ApplicationContext;

/**
 *
 * @author Yonathan
 */
public class Dashboard extends UserviewMenu {

    @Override
    public String getCategory() {
        return "HKM Element";
    }

    @Override
    public String getIcon() {
        return "/plugin/org.joget.apps.userview.lib.RunProcess/images/grid_icon.gif";
    }

    @Override
    public String getRenderPage() {
        Map<String, Object> dataModel = new HashMap<String, Object>();
        String templatePath = "dashboard.ftl";
        String noSeri = this.getPropertyString("noSeri");

        ApplicationContext appContext = AppUtil.getApplicationContext();
        PluginManager pluginManager = (PluginManager) appContext.getBean("pluginManager");
        DataSource ds = (DataSource) appContext.getBean("setupDataSource");
        WorkflowUserManager workflowUserManager = (WorkflowUserManager) appContext.getBean("workflowUserManager");
        DirectoryManager dm = (DirectoryManager) appContext.getBean("directoryManager");

        String username = workflowUserManager.getCurrentUsername();

        Chart mapJs = new Chart();
        Chart barChart = new Chart();
        Chart lineChart = new Chart();
        mapJs.setNoSeri(noSeri);
        mapJs.setNamaAlat("");
        mapJs.setContent("");

        Connection con = null;
        PreparedStatement ps = null, psRecResult = null;
        ResultSet rs = null, rsRecResult = null;

        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
        Date now = new Date();
        String today = sdf.format(now);

        try {
            con = ds.getConnection();
            // Cari user registered di alat mana aja
            String userSql
                    = "SELECT r.c_alat, r.c_group, a.c_lattitude, a.c_longitude, a.c_nama_alat "
                    + "FROM app_fd_hkm_md_user_register r "
                    + "INNER JOIN app_fd_hkm_md_alat a ON a.c_no_seri = c_alat "
                    + "WHERE r.c_active = 'Yes' "
                    + "AND r.c_alat = ? ";
            ps = con.prepareStatement(userSql);
            ps.setString(1, noSeri);
            rs = ps.executeQuery();
            while (rs.next()) {
                String noSeriAlat = rs.getString("c_alat");
                // Generate Map
                String map
                        = ""
                        + "      var uluru = {lat: " + rs.getString("c_lattitude") + ", lng: " + rs.getString("c_longitude") + "};\n"
                        + "      var map = new google.maps.Map(document.getElementById('hkm-" + rs.getString("c_alat") + "-map'), {\n"
                        + "        zoom: 13,\n"
                        + "        center: uluru\n"
                        + "      });\n"
                        + "      var marker = new google.maps.Marker({\n"
                        + "        position: uluru,\n"
                        + "        map: map\n"
                        + "      });\n";
                mapJs.setNoSeri(noSeriAlat);
                mapJs.setNamaAlat(rs.getString("c_nama_alat"));
                mapJs.setContent(map);

                String groups = rs.getString("c_group");
                String[] arrGroups = groups.split(";");
                boolean isInGroup = false;
                for (String group : arrGroups) {
                    Collection<Group> userGroups = dm.getGroupByUsername(username);
                    for (Group userGroup : userGroups) {
                        if (userGroup.getId().equals(group)) {
                            isInGroup = true;
                            break;
                        }
                    }
                }
                if (isInGroup) {

                    // Get DAILY RECORD 
                    String recResultSql
                            = "SELECT c_channel_no, c_result "
                            + "FROM app_fd_hkm_tmp_result_rec "
                            + "WHERE c_rec_date_time = ? "
                            + "AND c_no_seri_alat = ? ";
                    psRecResult = con.prepareStatement(recResultSql);
                    psRecResult.setString(1, today);
                    psRecResult.setString(2, noSeriAlat);
                    rsRecResult = psRecResult.executeQuery();
                    String barContent
                            = "var options = { "
                            + "     title: { "
                            + "                    text: \"Daily Record\" "
                            + "            }, "
                            + "            animationEnabled: true, "
                            + "            data: [ "
                            + "            { "
                            + "                type: \"column\", "
                            + "                dataPoints: [ ";
                    while (rsRecResult.next()) {
                        barContent
                                += "{ label: \"" + this.channelTranslator(rsRecResult.getString("c_channel_no")) + "\", "
                                + "y: " + rsRecResult.getString("c_result") + ", "
                                + "color:\"" + this.generateColor(rsRecResult.getString("c_result")) + "\""
                                + "},";
                    }
                    barContent = this.removeLastChar(barContent);
                    barContent
                            += "] "
                            + "            } "
                            + "            ] "
                            + "	}; "
                            + "	$(\"#chartContainer\").CanvasJSChart(options);";

                    barChart.setNoSeri(noSeriAlat);
                    barChart.setNamaAlat(rs.getString("c_nama_alat"));
                    barChart.setContent(barContent);

                    // Get WEEKLY RECORD 
                    String lineContent
                            = "var optionsSpline = { \n "
                            + "                title: { \n "
                            + "			text: \"Weekly Record\" \n"
                            + "		},\n"
                            + "                animationEnabled: true, \n"
                            + "		data: [ \n"
                            + "		{ \n"
                            + "			type: \"spline\", //change it to line, area, column, pie, etc \n"
                            + "			dataPoints: [ \n";
                    String[] days = this.getDaysInWeek();
                    int daysCounter = 1;
                    for (String day : days) {
                        String loopResult
                                = "SELECT c_channel_no, c_result \n "
                                + "FROM app_fd_hkm_tmp_result_rec \n "
                                + "WHERE c_rec_date_time = ? \n "
                                + "AND c_no_seri_alat = ? \n "
                                + "ORDER BY c_result DESC \n "
                                + "LIMIT 1";
                        psRecResult = con.prepareStatement(loopResult);
                        psRecResult.setString(1, day);
                        psRecResult.setString(2, noSeriAlat);
                        rsRecResult = psRecResult.executeQuery();
                        while (rsRecResult.next()) {
                            lineContent
                                    += "{ "
                                    + "label: \"" + this.getDaysLabel(daysCounter) + "\", "
                                    + "y: " + rsRecResult.getString("c_result") + ", "
                                    + "markerColor: \"" + this.generateColor(rsRecResult.getString("c_result")) + "\" "
                                    + "}, ";
                        }
                        daysCounter++;
                    }
                    lineContent = this.removeLastChar(lineContent);
                    lineContent
                            += "] \n"
                            + "		} \n"
                            + "		] \n"
                            + "	}; \n"
                            + " \n"
                            + "	$(\"#weeklyContainer\").CanvasJSChart(optionsSpline); ";
                    
                    lineChart.setNoSeri(noSeriAlat);
                    lineChart.setNamaAlat(rs.getString("c_nama_alat"));
                    lineChart.setContent(lineContent);
                }
            }
        } catch (SQLException ex) {
            LogUtil.error(Dashboard.class.getName(), ex, ex.getMessage());
        } finally {
            try {
                if (rsRecResult != null) {
                    rsRecResult.close();
                }
                if (rs != null) {
                    rs.close();
                }
                if (psRecResult != null) {
                    psRecResult.close();
                }
                if (ps != null) {
                    ps.close();
                }
                if (con != null) {
                    con.close();
                }
            } catch (Exception ex) {
                LogUtil.error(Dashboard.class.getName(), ex, ex.getMessage());
            }
        }
        dataModel.put("map", mapJs);
        dataModel.put("barChart", barChart);
        dataModel.put("lineChart", lineChart);
        String htmlContent = pluginManager.getPluginFreeMarkerTemplate(dataModel, Dashboard.class.getName(), "/templates/" + templatePath, "messages/dashboard");
        return htmlContent;
    }

    @Override
    public boolean isHomePageSupported() {
        return true;
    }

    @Override
    public String getDecoratedMenu() {
        return null;
    }

    public String getName() {
        return "AQMS - Dashboard";
    }

    public String getVersion() {
        return "1.0";
    }

    public String getDescription() {
        return "Dashboard View for HKM AQMS";
    }

    public String getLabel() {
        return "AQMS - Dashboard";
    }

    public String getClassName() {
        return this.getClass().getName();
    }

    public String getPropertyOptions() {
        return AppUtil.readPluginResource(getClass().getName(), "/properties/dashboard.json", null, true, "messages/dashboard");
    }

    private String channelTranslator(String channelNo) {
        int no = Integer.parseInt(channelNo);
        String result = "";
        switch (no) {
            case 1:
                result = "CO";
                break;
            case 2:
                result = "O3";
                break;
            case 3:
                result = "NO2";
                break;
            case 4:
                result = "C6H6";
                break;
            case 5:
                result = "T";
                break;
            case 6:
                result = "Rh";
                break;
            case 7:
                result = "Noise";
                break;
            case 8:
                result = "SO2";
                break;
            case 9:
                result = "";
                break;
            case 10:
                result = "PM10";
                break;
        }
        return result;
    }

    private String generateColor(String param) {
        double input = Double.parseDouble(param);
        if (input <= 50) {
            return "#01DF01";
        } else if (50 < input && input <= 100) {
            return "#0174DF";
        } else if (100 < input && input <= 199) {
            return "#FFFF00";
        } else if (199 < input && input <= 299) {
            return "#FF0000";
        } else if (299 < input && input <= 500) {
            return "#000000";
        }
        return "";
    }

    private String removeLastChar(String str) {
        char tmp = str.charAt(str.length() - 1);
        if (tmp != ',') {
            return str;
        } else {
            return str.substring(0, str.length() - 1);
        }

    }

    private String[] getDaysInWeek() {
        Calendar now = Calendar.getInstance();
        SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd");

        String[] days = new String[7];
        int delta = -now.get(GregorianCalendar.DAY_OF_WEEK) + 1; //add 2 if your week start on monday
        now.add(Calendar.DAY_OF_MONTH, delta);
        for (int i = 0; i < 7; i++) {
            days[i] = format.format(now.getTime());
            now.add(Calendar.DAY_OF_MONTH, 1);
        }
        return days;
    }

    private String getDaysLabel(int day) {
        switch (day) {
            case 1:
                return "M";
            case 2:
                return "S";
            case 3:
                return "S";
            case 4:
                return "R";
            case 5:
                return "K";
            case 6:
                return "J";
            case 7:
                return "S";
        }
        return "";
    }
}
