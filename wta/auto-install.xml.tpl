<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<AutomatedInstallation langpack="prt">
    <com.izforge.izpack.panels.htmlhello.HTMLHelloPanel id="hello.panel"/>
    <com.izforge.izpack.panels.htmlinfo.HTMLInfoPanel id="linux"/>
    <com.izforge.izpack.panels.userinput.UserInputPanel id="database.panel">
        <entry key="isTNS" value="false"/>
        <entry key="isSID" value="false"/>
        <entry key="hostname" value="${WTA_ORACLE_HOST}"/>
        <entry key="port" value="${WTA_ORACLE_PORT}"/>
        <entry key="sid" value="${ORACLE_PDB}"/>
        <entry key="dbusername" value="${SCHEMA_DESTINO}"/>
        <entry key="dbpassword" value="${SCHEMA_PASSWORD}"/>
        <entry key="loja" value="${WTA_LOJA}"/>
        <entry key="empresa" value="${WTA_EMPRESA}"/>
    </com.izforge.izpack.panels.userinput.UserInputPanel>
    <com.izforge.izpack.panels.userinput.UserInputPanel id="server.panel">
        <entry key="serverhost" value="${WTA_SERVER_HOST}"/>
        <entry key="hostserver.use" value="true"/>
        <entry key="http" value="${WTA_HTTP_PORT}"/>
        <entry key="ssh" value="${WTA_SSH_PORT}"/>
        <entry key="rmi" value="${WTA_RMI_PORT}"/>
        <entry key="brokerport" value="${WTA_ARTEMIS_PORT}"/>
        <entry key="useProxy" value="false"/>
    </com.izforge.izpack.panels.userinput.UserInputPanel>
    <com.izforge.izpack.panels.defaulttarget.DefaultTargetPanel id="DefaultTargetPanel_6">
        <installpath>/opt/pcsist/produtos/winthor/</installpath>
    </com.izforge.izpack.panels.defaulttarget.DefaultTargetPanel>
    <com.izforge.izpack.panels.packs.PacksPanel id="packs.panel"/>
    <com.izforge.izpack.panels.summary.SummaryPanel id="summary.panel"/>
    <com.izforge.izpack.panels.install.InstallPanel id="install.panel"/>
    <com.izforge.izpack.panels.process.ProcessPanel id="job.configuration"/>
    <com.izforge.izpack.panels.finish.FinishPanel id="finish.panel"/>
</AutomatedInstallation>
