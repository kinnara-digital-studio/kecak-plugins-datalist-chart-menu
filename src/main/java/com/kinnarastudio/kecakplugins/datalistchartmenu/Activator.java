package com.kinnarastudio.kecakplugins.datalistchartmenu;

import java.util.ArrayList;
import java.util.Collection;

import com.kinnarastudio.kecakplugins.datalistchartmenu.userview.menu.DataListChartUserviewMenu;
import com.kinnarastudio.kecakplugins.datalistchartmenu.userview.menu.EnhDatalistChartUserviewMenu;
import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceRegistration;

public class Activator implements BundleActivator {

    protected Collection<ServiceRegistration> registrationList;

    public void start(BundleContext context) {
        registrationList = new ArrayList<ServiceRegistration>();

        //Register plugin here
        registrationList.add(context.registerService(DataListChartUserviewMenu.class.getName(), new DataListChartUserviewMenu(), null));
//        registrationList.add(context.registerService(EnhDatalistChartUserviewMenu.class.getName(), new EnhDatalistChartUserviewMenu(), null));
    }

    public void stop(BundleContext context) {
        for (ServiceRegistration registration : registrationList) {
            registration.unregister();
        }
    }
}