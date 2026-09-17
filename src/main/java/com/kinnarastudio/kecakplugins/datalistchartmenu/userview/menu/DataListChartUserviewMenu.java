package com.kinnarastudio.kecakplugins.datalistchartmenu.userview.menu;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.ResourceBundle;
import java.util.WeakHashMap;
import java.util.regex.Pattern;

import javax.servlet.http.HttpServletRequest;

import org.joget.apps.app.dao.DatalistDefinitionDao;
import org.joget.apps.app.model.AppDefinition;
import org.joget.apps.app.model.DatalistDefinition;
import org.joget.apps.app.service.AppUtil;
import org.joget.apps.app.service.MobileUtil;
import org.joget.apps.datalist.model.DataList;
import org.joget.apps.datalist.model.DataListCollection;
import org.joget.apps.datalist.model.DataListColumn;
import org.joget.apps.datalist.model.DataListColumnFormat;
import org.joget.apps.datalist.model.DataListFilterQueryObject;
import org.joget.apps.datalist.service.DataListService;
import org.joget.apps.userview.model.UserviewMenu;
import org.joget.commons.util.LogUtil;
import org.joget.plugin.base.PluginManager;
import org.joget.workflow.util.WorkflowUtil;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.springframework.context.ApplicationContext;

/**
 * @author aristo
 */
public class DataListChartUserviewMenu extends UserviewMenu {

    private WeakHashMap<String, DataList> datalistCache = new WeakHashMap<>();

    @Override
    public String getCategory() {
        return "Kecak";
    }

    @Override
    public String getIcon() {
        return "/plugin/org.joget.apps.userview.lib.RunProcess/images/grid_icon.gif";
    }

    @Override
    public String getRenderPage() {
        final String template;
        final String chartType = getPropertyString("chartType");

        LogUtil.info(getClassName(), "Chart Type: " + chartType);

        if (chartType.equals("barline") || chartType.equals("gauge")) {
            template = "/templates/DataListD3ChartUserviewMenu.ftl";
        } else {
            template = "/templates/DataListChartUserviewMenu.ftl";
        }

        return getRenderPage(template, "/templates/Error.ftl");
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
        return "DataList Chart";
    }

    public String getVersion() {
        PluginManager pluginManager = (PluginManager) AppUtil.getApplicationContext().getBean("pluginManager");
        ResourceBundle resourceBundle = pluginManager.getPluginMessageBundle(getClassName(), "/messages/BuildNumber");
        String buildNumber = resourceBundle.getString("buildNumber");
        return buildNumber;
    }

    public String getDescription() {
        return "Artifact ID : " + getClass().getPackage().getImplementationTitle();
    }

    public String getLabel() {
        return getName();
    }

    public String getClassName() {
        return getClass().getName();
    }

    public String getPropertyOptions() {
        return AppUtil.readPluginResource(getClass().getName(), "/properties/DataListChartUserviewMenu.json", null, true, "/messages/DataListChartUserviewMenu");
    }

    private DataList getDataList(String datalistId) {
        ApplicationContext ac = AppUtil.getApplicationContext();
        AppDefinition appDef = AppUtil.getCurrentAppDefinition();

        if (datalistCache.containsKey(datalistId))
            return datalistCache.get(datalistId);

        DataListService dataListService = (DataListService) ac.getBean("dataListService");
        DatalistDefinitionDao datalistDefinitionDao = (DatalistDefinitionDao) ac.getBean("datalistDefinitionDao");
        DatalistDefinition datalistDefinition = (DatalistDefinition) datalistDefinitionDao.loadById(datalistId, appDef);
        if (datalistDefinition != null) {
            DataList dataList = dataListService.fromJson(datalistDefinition.getJson());
            datalistCache.put(datalistId, dataList);
            return dataList;
        }
        return null;
    }

    private void getCollectFilters(DataList dataList, Map<String, Object> requestParameters) {
        DataListColumn[] columns = dataList.getColumns();

        Comparator<DataListColumn> comparator = Comparator.comparing(DataListColumn::getName);

        Arrays.sort(columns, comparator);
        DataListColumn key = new DataListColumn();
        for (Map.Entry<String, Object> entry : requestParameters.entrySet()) {
            key.setName(entry.getKey());
            int index = Arrays.binarySearch(columns, key, comparator);
            if (index >= 0) {
                try {
                    // parameter is one of the filter
                    DataListFilterQueryObject filter = new DataListFilterQueryObject();
                    filter.setOperator("AND");
                    // this is the default pattern of datalist filter query is "lower([field]) like lower(?)"
                    filter.setQuery("lower(" + entry.getKey() + ") like lower(?)");
                    if (entry.getValue() instanceof String[]) {
                        String[] parameterValues = (String[]) entry.getValue();
                        String[] values = new String[parameterValues.length];
                        for (int i = 0, size = parameterValues.length; i < size; i++) {
                            // this is the default pattern of datalist filter value is %[value]%
                            values[i] = "%" + parameterValues[i] + "%";
                        }
                        filter.setValues(values);
                    } else {
                        filter.setValues(new String[]{"%" + entry.getValue().toString() + "%"});
                    }
                    dataList.addFilterQueryObject(filter);
                } catch (Exception e) {
                    LogUtil.error(getClassName(), e, "Error creating filter [" + entry.getKey() + "]");
                }
            }
        }
    }

    private String format(DataList dataList, Map<String, String> row, String field) {
        if (dataList.getColumns() != null) {
            for (DataListColumn column : dataList.getColumns()) {
                if (field.equals(column.getName())) {
                    String value = String.valueOf(row.get(field));
                    if (column.getFormats() != null) {
                        for (DataListColumnFormat format : column.getFormats()) {
                            if (format != null) {
                                return format.format(dataList, column, row, value).replaceAll("<[^>]*>", "");
                            }
                        }
                    } else {
                        return value;
                    }
                }
            }
        }
        return null;
    }

    protected String getRenderPage(final String template, final String errorTemplate) {
        final HttpServletRequest request = WorkflowUtil.getHttpServletRequest();
        final ApplicationContext appContext = AppUtil.getApplicationContext();
        final PluginManager pluginManager = (PluginManager) appContext.getBean("pluginManager");
        final boolean isMobileView = MobileUtil.isMobileView();

        final Map<String, Object> dataModel = new HashMap<>();

        final DataList dataList = getDataList(getPropertyString("dataListId"));
        if (dataList == null) {
            dataModel.put("errorMessage", "DataList [" + getPropertyString("dataListId") + "] is null");
            return pluginManager.getPluginFreeMarkerTemplate(dataModel, getClassName(), errorTemplate, "/messages/DataListChartUserviewMenu");
        }

        getCollectFilters(dataList, ((Map<String, Object>) getRequestParameters()));
        final DataListCollection<Map<String, String>> collections = dataList.getRows(DataList.MAXIMUM_PAGE_SIZE, 0);
        final JSONArray data = new JSONArray();
        for (Map<String, String> row : collections) {
            try {
                JSONObject jsonRow = new JSONObject();
                for (String field : row.keySet()) {
                    String value = format(dataList, row, field);
                    if (value != null)
                        jsonRow.put(field, value);
                    else if (row.get(field) != null)
                        jsonRow.put(field, row.get(field));
                }
                data.put(jsonRow);
            } catch (JSONException e) {
                data.put(new JSONObject(row));
                LogUtil.error(getClassName(), e, e.getMessage());
            }
        }

        // use datalist's primary key if label field not specified
        if (getPropertyString("labelField") == null || getPropertyString("labelField").isEmpty()) {
            setProperty("labelField", dataList.getBinder().getPrimaryKeyColumnName());
        }

        dataModel.put("data", data);

        try {
            final JSONArray customColors = new JSONArray(getProperty("customColors"));
            dataModel.put("customColors", customColors);
        } catch (JSONException e) {
            LogUtil.error(getClassName(), e, e.getMessage());
        }

        final DataListColumn[] columns = dataList.getColumns();
        final Comparator<DataListColumn> comparator = Comparator.comparing(DataListColumn::getName);

        Arrays.sort(columns, comparator);

        final DataListColumn column = new DataListColumn();

        // set label, sync between maxColor and minColor
        Object[] valueFields = (Object[]) getProperty("valueFields");
        if (valueFields != null) {
            for (Object o : valueFields) {
                Map<String, String> row = (Map<String, String>) o;
                if ((row.get("maxColor") == null || row.get("maxColor").isEmpty()) && row.get("minColor") != null && !row.get("minColor").isEmpty()) {
                    row.put("maxColor", row.get("minColor"));
                }

                if ((row.get("minColor") == null || row.get("minColor").isEmpty()) && row.get("maxColor") != null && !row.get("maxColor").isEmpty()) {
                    row.put("minColor", row.get("maxColor"));
                }

                column.setName(row.get("field"));
                int index = Arrays.binarySearch(columns, column, comparator);
                row.put("label", index >= 0 ? columns[index].getLabel() : row.get("field"));
            }
        }
        
        Object[] barlineFields = (Object[]) getProperty("barlineLineFields");
        if (barlineFields != null) {
            for (Object o : barlineFields) {
                Map<String, String> row = (Map<String, String>) o;
                column.setName(row.get("field"));
                int index = Arrays.binarySearch(columns, column, comparator);
                row.put("label", index >= 0 ? columns[index].getLabel() : row.get("field"));
            }
        }

        dataModel.put("className", getClassName());
        dataModel.put("element", this);
        dataModel.put("pluginName", getName());

        final boolean isEmbedded = (boolean) request.getAttribute("embed");
        dataModel.put("isEmbedded", isEmbedded);

        dataModel.put("customHeader", AppUtil.processHashVariable(getPropertyString("customHeader"), null, null, null));
        dataModel.put("customFooter", AppUtil.processHashVariable(getPropertyString("customFooter"), null, null, null));

        // filter template
        final List<String> filterTemplates = new ArrayList<>();

        final Pattern pagePattern = Pattern.compile("id='d-[0-9]+-p'|id='d-[0-9]+-ps'");
        for (final String filterTemplate : dataList.getFilterTemplates()) {
            if (!pagePattern.matcher(filterTemplate).find()) {
                filterTemplates.add(filterTemplate);
            }
        }

        dataModel.put("filterTemplates", filterTemplates.toArray(new String[0]));
        dataModel.put("showDataListFilter", !isEmbedded && "true".equals(getPropertyString("showFilter")) && !isMobileView && dataList.getFilters().length > 0);

        dataModel.put("dataListId", dataList.getId());

        final String htmlContent = pluginManager.getPluginFreeMarkerTemplate(dataModel, getClassName(), template, "/messages/DataListChartUserviewMenu");
        return htmlContent;
    }
}
