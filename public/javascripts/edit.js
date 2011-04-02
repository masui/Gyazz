//
// $Date: 2005-11-28 15:02:58 +0900 (Mon, 28 Nov 2005) $
//

var timeout;

//var TOP = "http://gyazz.com"
var root = "http://masui.sfc.keio.ac.jp/Gyazz"

document.onkeyup = keyup;

function keyup(event){
  if(timeout) clearTimeout(timeout);
  timeout = setTimeout("writedata()",2000);
}

function createXmlHttp(){
    if (window.ActiveXObject) {
        return new ActiveXObject("Microsoft.XMLHTTP");
    } else if (window.XMLHttpRequest) {
        return new XMLHttpRequest();
    } else {
        return null;
    }
}

function writedata(){
  xmlhttp = createXmlHttp();
  xmlhttp.open("POST", root + "/__write" , true);
  xmlhttp.setRequestHeader("Content-Type" , "application/x-www-form-urlencoded"); // これで送るとSinatraが受け付けるらしい
  //http://www.gittr.com/index.php/archive/getting-data-into-a-sinatra-app に解説あり

  var textarea = document.getElementById('contents');
  datastr = textarea.value;

  postdata = "data=" + encodeURIComponent(name + "\n" + title + "\n" + orig_md5 + "\n" + datastr)

  xmlhttp.send(postdata);
  xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState==4) {
      response = xmlhttp.responseText;
      //  alert(response);
      if(response == 'conflict'){
        // 再読み込み
        getdata();
      }
      else {
        orig_md5 = MD5_hexhash(utf16to8(datastr));
      }
    }
  }
}

function getdata(){ // 20050815123456.utf のようなテキストを読み出し
  version = 0;
  data = [];
  xmlhttp = createXmlHttp();
  file = root + "/" + name + "/" + title + "/text/" + version;
  xmlhttp.open("GET", file , true);
  xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState==4) {
      xx = xmlhttp.responseText;
      d = xx.split(/\n/);
      datestr = d.shift();
      data = [];
      dt = [];
      for(var i=0;i<d.length;i++){
        s = d[i]
        if(s != ''){
          t = 0;
          if(version > 0){
            s.match(/^(.*) ([0-9]*)$/);
            s = RegExp.$1;
            t = RegExp.$2;
          }
          dt.push(Number(t));
          data.push(s);
        }
      }
      datastr = data.join("\n")+"\n";
      document.getElementById('contents').value = datastr;
      orig_md5 = MD5_hexhash(utf16to8(datastr));
    }
  }
  xmlhttp.send("");
}


