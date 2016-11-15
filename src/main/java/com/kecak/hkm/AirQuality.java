package com.kecak.hkm;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author Yonathan
 */
public class AirQuality {
    private String recDate;
    private String noSeri;
    private String channelNo;
    private Double result;
    private Double average;

    /**
     * @return the recDate
     */
    public String getRecDate() {
        return recDate;
    }

    /**
     * @param recDate the recDate to set
     */
    public void setRecDate(String recDate) {
        this.recDate = recDate;
    }

    /**
     * @return the noSeri
     */
    public String getNoSeri() {
        return noSeri;
    }

    /**
     * @param noSeri the noSeri to set
     */
    public void setNoSeri(String noSeri) {
        this.noSeri = noSeri;
    }

    /**
     * @return the channelNo
     */
    public String getChannelNo() {
        return channelNo;
    }

    /**
     * @param channelNo the channelNo to set
     */
    public void setChannelNo(String channelNo) {
        this.channelNo = channelNo;
    }

    /**
     * @return the result
     */
    public Double getResult() {
        return result;
    }

    /**
     * @param result the result to set
     */
    public void setResult(Double result) {
        this.result = result;
    }

    /**
     * @return the average
     */
    public Double getAverage() {
        return average;
    }

    /**
     * @param average the average to set
     */
    public void setAverage(Double average) {
        this.average = average;
    }
}