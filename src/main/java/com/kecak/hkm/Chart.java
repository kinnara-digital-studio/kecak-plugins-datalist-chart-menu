/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.kecak.hkm;

/**
 *
 * @author Yonathan
 */
public class Chart {
    private String namaAlat;
    private String noSeri;
    private String content;
    
    public Chart(){
        content = "";
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
     * @return the content
     */
    public String getContent() {
        return content;
    }

    /**
     * @param content the content to set
     */
    public void setContent(String content) {
        this.content = content;
    }

    /**
     * @return the namaAlat
     */
    public String getNamaAlat() {
        return namaAlat;
    }

    /**
     * @param namaAlat the namaAlat to set
     */
    public void setNamaAlat(String namaAlat) {
        this.namaAlat = namaAlat;
    }
}
