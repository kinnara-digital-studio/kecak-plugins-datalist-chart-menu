package com.kinnara.kecakplugins.dashboardmenu;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.joget.apps.app.dao.DatalistDefinitionDao;
import org.joget.apps.app.model.AppDefinition;
import org.joget.apps.app.model.DatalistDefinition;
import org.joget.apps.app.service.AppUtil;
import org.joget.apps.datalist.model.DataList;
import org.joget.apps.datalist.model.DataListCollection;
import org.joget.apps.datalist.model.DataListColumn;
import org.joget.apps.datalist.model.DataListColumnFormat;
import org.joget.apps.datalist.model.DataListFilterQueryObject;
import org.joget.apps.datalist.service.DataListService;
import org.joget.apps.userview.model.UserviewMenu;
import org.joget.commons.util.LogUtil;
import org.joget.plugin.base.PluginManager;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.springframework.context.ApplicationContext;

/**
 * @author aristo
 */
public class Dashboard extends UserviewMenu {

	private Map<String, DataList> datalistCache = new HashMap<String, DataList>();

	@Override
	public String getCategory() {
		return "Kecak Enterprise";
	}

	@Override
	public String getIcon() {
		return "/plugin/org.joget.apps.userview.lib.RunProcess/images/grid_icon.gif";
	}

	@Override
	public String getRenderPage() {
		Map<String, Object> dataModel = new HashMap<String, Object>();

		ApplicationContext appContext    = AppUtil.getApplicationContext();
		PluginManager      pluginManager = (PluginManager) appContext.getBean("pluginManager");

		DataList dataList = getDataList(getPropertyString("dataListId"));
		getCollectFilters(dataList);

		if (dataList != null) {
			DataListCollection<Map<String, String>> collections = dataList.getRows();
			JSONArray                               data        = new JSONArray();
			for(Map<String, String> row : collections) {        		
				try {
					JSONObject jsonRow = new JSONObject();
					for(String field : row.keySet()) {
						String value = format(dataList, row, field);
						if(value != null)
							jsonRow.put(field, value);
						else if(row.get(field) != null)
							jsonRow.put(field, row.get(field));
					}
					data.put(jsonRow);
				} catch (JSONException e) {
					data.put(new JSONObject(row));
					LogUtil.error(getClassName(), e, "");
				}
			}


			// use datalist's primary key if label field not specified
			if (getPropertyString("labelField") == null || getPropertyString("labelField").isEmpty())
				setProperty("labelField", dataList.getBinder().getPrimaryKeyColumnName());

			dataModel.put("data", data);
		}


		try {
			JSONArray customColors = new JSONArray(getProperty("customColors"));
			dataModel.put("customColors", customColors);
		} catch (JSONException e) {
			LogUtil.error(getClassName(), e, "");
		}

		DataListColumn[] columns = dataList.getColumns();
		Comparator<DataListColumn> comparator = new Comparator<DataListColumn>() {
			public int compare(DataListColumn o1, DataListColumn o2) {
				return o1.getName().compareTo(o2.getName());
			}
		};

		Arrays.sort(columns, comparator);

		DataListColumn column = new DataListColumn();
		// set label, sync between maxColor and minColor
		for (Object o : (Object[]) getProperty("valueFields")) {
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

		dataModel.put("className", getClassName());
		dataModel.put("element", this);

		dataModel.put("customHeader", AppUtil.processHashVariable(getPropertyString("customHeader"), null, null, null));
		dataModel.put("customFooter", AppUtil.processHashVariable(getPropertyString("customFooter"), null, null, null));


		String htmlContent = pluginManager.getPluginFreeMarkerTemplate(dataModel, getClassName(), "/templates/dashboard.ftl", "/messages/dashboard");
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
		return "Kecak Dashboard";
	}

	public String getVersion() {
		return getClass().getPackage().getImplementationVersion();
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
		return AppUtil.readPluginResource(getClass().getName(), "/properties/dashboard.json", null, true, "/messages/dashboard");
	}

	private DataList getDataList(String datalistId) {
		ApplicationContext ac     = AppUtil.getApplicationContext();
		AppDefinition      appDef = AppUtil.getCurrentAppDefinition();

		if (datalistCache.containsKey(datalistId))
			return datalistCache.get(datalistId);

		DataListService       dataListService       = (DataListService) ac.getBean("dataListService");
		DatalistDefinitionDao datalistDefinitionDao = (DatalistDefinitionDao) ac.getBean("datalistDefinitionDao");
		DatalistDefinition    datalistDefinition    = (DatalistDefinition) datalistDefinitionDao.loadById(datalistId, appDef);
		if (datalistDefinition != null) {
			DataList dataList = dataListService.fromJson(datalistDefinition.getJson());
			datalistCache.put(datalistId, dataList);
			return dataList;
		}
		return null;
	}

	private void getCollectFilters(DataList dataList) {
		List<DataListFilterQueryObject> result = new ArrayList<DataListFilterQueryObject>();

		DataListColumn[] columns = dataList.getColumns();

		Comparator<DataListColumn> comparator = new Comparator<DataListColumn>() {
			public int compare(DataListColumn o1, DataListColumn o2) {
				return o1.getName().compareTo(o2.getName());
			}	  
		};

		Arrays.sort(columns, comparator);
		DataListColumn key = new DataListColumn();
		for(Map.Entry<String, Object> entry : ((Map<String, Object>)getRequestParameters()).entrySet()) {
			key.setName(entry.getKey());
			int index = Arrays.binarySearch(columns, key, comparator);
			if(index >= 0) {
				try {
					// parameter is one of the filter
					DataListFilterQueryObject filter = new DataListFilterQueryObject();
					filter.setOperator("AND");
					// this is the default pattern of datalist filter query is "lower([field]) like lower(?)"
					filter.setQuery("lower(" + entry.getKey() + ") like lower(?)");
					if(entry.getValue() instanceof String[]) {
						String[] parameterValues = (String[])entry.getValue();
						String[] values = new String[parameterValues.length];
						for(int i = 0, size = parameterValues.length; i< size; i++) {
							// this is the default pattern of datalist filter value is %[value]%
							values[i] = "%" + parameterValues[i] + "%";
						}
						filter.setValues(values);
					} else {
						filter.setValues( new String[] { "%" + entry.getValue().toString() + "%"});	
					}
					dataList.addFilterQueryObject(filter);
				} catch(Exception e) {
					LogUtil.error(getClassName(), e, "Error creating filter [" + entry.getKey() + "]");
				}
			}
		}
	}

	private String format(DataList dataList, Map<String, String> row, String field) {
		if(dataList.getColumns() != null) {
			for(DataListColumn column : dataList.getColumns()) {
				if(field.equals(column.getName())) {
					String value = String.valueOf(row.get(field));
					if(column.getFormats() != null) {
						for(DataListColumnFormat format : column.getFormats()) {
							if(format != null) {
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
}
