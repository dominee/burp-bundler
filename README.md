# burp-bundler

Bash script to create a Burp Suite bundle for air-gapped systems, or corporate VDIs.

## Bundled content

The script simply does the following:

* Downloads the latest (or scpecified) version of Burp Suite Pro windows installer (or jar) as `burpsuite_pro.exe`
* Downloads latest Jython an `jython-standalone.jar`
* Downloads and extracts all available Burp Extensions from the online store.
* Generates a `UserConfigPro.json` from a template
    - Add all the extensions to the config file as installed but disabled, using `jq` for json processing.
    - Enables a predefined list of extensions.
* Zips it into a nice ~1.3G archive named `burp-bundle.zip`

So this is what you get in the end.

```
Archive:  bundle/burp-bundle.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  11-22-2023 10:04   burp-bundle/
        0  11-21-2023 15:39   burp-bundle/0e61c786db0c4ac787a08c4516d52ccf/
     1065  09-05-2019 14:28   burp-bundle/0e61c786db0c4ac787a08c4516d52ccf/LICENSE
      128  09-05-2019 14:28   burp-bundle/0e61c786db0c4ac787a08c4516d52ccf/BappSignature.sig
    10058  09-05-2019 14:28   burp-bundle/0e61c786db0c4ac787a08c4516d52ccf/FransLinkfinder.py
     1571  09-05-2019 14:28   burp-bundle/0e61c786db0c4ac787a08c4516d52ccf/README.md
      170  09-05-2019 14:28   burp-bundle/0e61c786db0c4ac787a08c4516d52ccf/BappDescription.html
...
312323040  11-22-2023 11:12   burp-bundle/burpsuite_pro.exe
 47288881  11-22-2023 11:12   burp-bundle/jython-standalone.jar
   128259  11-22-2023 11:17   burp-bundle/UserConfigPro.json
...    
        0  11-21-2023 15:39   burp-bundle/16ac195454f8429baac1c5357b0d3952/
      128  01-25-2017 08:03   burp-bundle/16ac195454f8429baac1c5357b0d3952/BappSignature.sig
      264  01-25-2017 08:03   burp-bundle/16ac195454f8429baac1c5357b0d3952/BappDescription.html
        0  11-21-2023 15:39   burp-bundle/16ac195454f8429baac1c5357b0d3952/build/
        0  11-21-2023 15:39   burp-bundle/16ac195454f8429baac1c5357b0d3952/build/libs/
  1968893  01-25-2017 08:03   burp-bundle/16ac195454f8429baac1c5357b0d3952/build/libs/lair-all.jar
      303  01-25-2017 08:03   burp-bundle/16ac195454f8429baac1c5357b0d3952/BappManifest.bmf
---------                     -------
1682471117                     12029 files
```
