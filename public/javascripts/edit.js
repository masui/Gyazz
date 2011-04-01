//
// $Date: 2005-11-28 15:02:58 +0900 (Mon, 28 Nov 2005) $
//

var timeout;

var TOP = "http://gyazz.com"

document.onkeyup = keyup;

function keyup(event){
  if(timeout) clearTimeout(timeout);
  timeout = setTimeout("writedata()",2000);

  // 書き込みが必要な状態になると背景を黄色くしていたが、
  // ウザい気もするのでやめてみる。
  //var input = document.getElementById("contents");
  //input.style.backgroundColor = "#ffff80";
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
  xmlhttp.open("POST", TOP + "/programs/postdata.cgi" , true);
  xmlhttp.setRequestHeader("Content-Type" , "application/x-www-form-urlencoded");
  xmlhttp.setRequestHeader("Content-Type" , "text/html; charset=utf-8"); //2006/11/10追加 for Safari
  var textarea = document.getElementById('contents');
  data = textarea.value;
  //postdata = "data=" + encodeURIComponent(name + "\n" + title + "\n" + data);
  // xmlhttp.send(postdata);
  postdata = "data=" + encodeURIComponent(name + "\n" + title + "\n" + orig_md5 + "\n" + data);
  xmlhttp.send(postdata);
  xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState==4) {
      response = xmlhttp.responseText;
      if(response == 'collision'){
	  alert('書込み衝突が発生しました。別の場所で同時に修正が行なわれている可能性があります。リロードして編集をやり直して下さい。');
      }
      else {
	  orig_md5 = response;
      }
    }
  }
}
