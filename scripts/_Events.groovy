/*
 * Copyright (C) 2014 Atlas of Living Australia
 * All Rights Reserved.
 *
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 */

import org.apache.commons.lang.SystemUtils
import org.tmatesoft.svn.core.internal.io.dav.DAVRepositoryFactory
import org.tmatesoft.svn.core.internal.io.fs.FSRepositoryFactory
import org.tmatesoft.svn.core.internal.io.svn.SVNRepositoryFactoryImpl
import org.tmatesoft.svn.core.wc.SVNClientManager
import org.tmatesoft.svn.core.wc.SVNInfo
import org.tmatesoft.svn.core.wc.SVNRevision
import org.tmatesoft.svn.core.wc.SVNWCClient

eventCompileStart = { msg ->

    //new File("grails-app/views/_version.gsp").text = "svnversion".execute().text
    //}
    //eventWarStart = { type ->

    // taken from http://stackoverflow.com/a/5264078/249327
    println "******************* eventCompileStart *****************"
    try {
        // initialise SVNKit
        DAVRepositoryFactory.setup();
        SVNRepositoryFactoryImpl.setup();
        FSRepositoryFactory.setup();

        SVNClientManager clientManager = SVNClientManager.newInstance();
        //println "clientManager = " + clientManager.toString();
        SVNWCClient wcClient = clientManager.getWCClient();
        //println "wcClient = " + wcClient.toString();

        // the svnkit equivalent of "svn info"
        File baseFile = new File(basedir);

        //println "baseFile = " + baseFile.toString();
        SVNInfo svninfo = wcClient.doInfo(baseFile, SVNRevision.WORKING);
        //println "svninfo = " + svninfo.toString();

        def version = svninfo.revision
        println "Getting svn revision: ${version}"
        metadata.'svn.revision' = version.toString()
        // add other system info
        metadata.'java.version' = SystemUtils.JAVA_VERSION
        metadata.'java.name' = SystemUtils.JAVA_VM_NAME
        metadata.'build.hostname' = InetAddress.getLocalHost().getHostName()
        metadata.persist()
    }
    catch (Exception ex) {
        //something went wrong
        println "**************** SVN exception **************"
        println ex.getMessage();
    }

} // End eventCompileStart()