const net = require('net');
var counter = 1

var server = net.createServer((socket) => {
    socket.on('data', (data) => {
        console.log(`RECEIVED ` + counter)
        counter += 1
        console.log(data.toString());
        console.log("\n\n")
  });

    socket.end("HTTP/1.1 200 OK\r\n")
//                        + "Server: MacOSX/10.12.4 UPnP/1.0 MyApp/0.1\r\n"
//                        + "Connection: close\r\n")
//                        + "\r\n")

    socket.on('error', (err) => {
        console.error(err);
    });
}).on('error', (err) => {
  console.error(err);
});

server.listen(1234, () => {
  console.log('opened server on', server.address().port);
})

//curl -v http://192.168.1.17:1400/MediaRenderer/RenderingControl/Event -H "CALLBACK: <http://192.168.1.22:1234>" -H "NT: upnp:event" -H "TIMEOUT: Second-1800" -X SUBSCRIBE
//curl -v http://192.168.1.17:1400/MediaRenderer/RenderingControl/Event -H "HOST: 192.168.1.17:1400" -H "SID: uuid:RINCON_48A6B888B19601400_sub0000001118" -X UNSUBSCRIBE


//"NOTIFY / HTTP/1.1\r\nHOST: 192.168.1.22:1234\r\nCONNECTION: close\r\nCONTENT-TYPE: text/xml\r\nCONTENT-LENGTH: 438\r\nNT: upnp:event\r\nNTS: upnp:propchange\r\nSID: uuid:RINCON_48A6B888B19601400_sub0000000413\r\nSEQ: 3\r\nX-SONOS-SERVICETYPE: RenderingControl\r\n\r\n<e:propertyset xmlns:e=\"urn:schemas-upnp-org:event-1-0\"><e:property><LastChange>&lt;Event xmlns=&quot;urn:schemas-upnp-org:metadata-1-0/RCS/&quot;&gt;&lt;InstanceID val=&quot;0&quot;&gt;&lt;Volume channel=&quot;Master&quot; val=&quot;40&quot;/&gt;&lt;Volume channel=&quot;LF&quot; val=&quot;100&quot;/&gt;&lt;Volume channel=&quot;RF&quot; val=&quot;100&quot;/&gt;&lt;/InstanceID&gt;&lt;/Event&gt;</LastChange></e:property></e:propertyset>
//
//
///MediaRenderer/RenderingControl/Control
//
//<s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'>
//                <s:Body> 
//                <u:\ GetVolume xmlns:u='urn:schemas-upnp-org:service:RenderingControl:1'>
//                    <InstanceID>0</InstanceID>
//                <Channel>Master</Channel>
//                </u:GetVolume> 
//                </s:Body>
//                </s:Envelope>