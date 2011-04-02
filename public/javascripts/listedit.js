//
// $Date: 2005-11-28 15:02:58 +0900 (Mon, 28 Nov 2005) $
//

// 以下はpage.cgiから与えられる
// var name = '#{name_escape}';\n" +
// var title = '#{title_escape}';\n" +
// var version = #{version};\n"

var name_id;
var title_id;

var editline = -1;
var eline = -1;
var timeout;

var headchar = '';
var data = [];
var dt = []          // 背景色???
var doi = [];
var zoomlevel = 0;

var query = null;
var timemachine = false;
var datestr = '';

var reloadTimeout = null; //放っておくとリロードするように
var reloadInterval = 10 * 60 * 1000; // 10分ごとにリロード

var orig_md5; // getdata()したときのMD5

// var TOP = "http://gyazz.com"

var KC = {
  tab:9, enter:13, left:37, up:38, right:39, down:40
};

// keypressを定義しておかないとFireFox上で矢印キーを押してときカーソルが動いてしまう
document.onkeypress = keypress;
//document.addEventListener('keypress', keypress, true); 

function keypress(event){
  var kc = keycode(event);
  if(kc == KC.enter)  event.preventDefault();
  if(kc == KC.enter){
    // 1行追加 
    // IME確定でもkeydownイベントが出てしまうのでここで定義が必要!
    if(editline >= 0){
      addblankline(editline+1,indent(editline));
      zoomlevel = 0;
      calcdoi();
      display();
    }
    return false;
  }
  // カーソルキーやタブを無効化
  if(!shiftkey(event) && (kc == KC.down || kc == KC.up || kc == KC.tab)){
    return false;
  }
}

// これは普通のやり方
//body.onload = onload;
//function onload(){
//  setup();
//  getdata();
//}

// SafariとかIEとかでaddEventListenerが動かない
document.onkeydown = keydown;
//document.addEventListener('keydown', keydown, true); 

document.onkeyup = keyup;
//document.addEventListener('keyup', keyup, true); 
document.onmousedown = mousedown;
document.onmouseup = mouseup;

function keycode(event)
{
  if(document.all)                       //e4,e5,e6用
    return window.event.keyCode;
  if(document.layers||document.getElementById){ // NS, FF
    a = event.keyCode
    if(a != 0){ return a }
    return event.which
  }
}

function shiftkey(event)
{
  if(document.all)                       //e4,e5,e6用
    return window.event.shiftKey;
  if(document.layers||document.getElementById) // NS, FF
    return event.shiftKey;
}

function ctrlkey(event)
{
  if(document.all)                       //e4,e5,e6用
    return window.event.ctrlKey;
  if(document.layers||document.getElementById) // NS, FF
    return event.ctrlKey;
}

function getMouseX(e){
  if(window.opera)                            //o6用
      return e.clientX
  else if(document.all)                       //e4,e5,e6用
      return document.body.scrollLeft+event.clientX
  else if(document.layers||document.getElementById)
      return e.pageX                          //n4,n6,m1用
}

function getMouseY(e){
  if(window.opera)                            //o6用
      return e.clientY
  else if(document.all)                       //e4,e5,e6用
      return document.body.scrollTop+event.clientY
  else if(document.layers||document.getElementById)
      return e.pageY                          //n4,n6,m1用
}

function bgcol_simple(t){
  if(t < 1000) return '#ffffff';
  if(t < 3000) return '#eeeeee';
  if(t < 10000) return '#cccccc';
  if(t < 30000) return '#bbbbbb';
  if(t < 100000) return '#aaaaaa';
  if(t < 300000) return '#999999';
  return '#888888';
}

function hex2(v){
  return ("0" + v.toString(16)).slice(-2);
}

function bgcol(t){
  // データの古さに応じて行の色を変える
  var table = [
           [0,                        256, 256,   0], 
           [24 * 60 * 60,             256, 100,  20],
           [7 * 24 * 60 * 60,         100, 100,  50],
           [30 * 24 * 60 * 60,         50, 100, 100],
           [180 * 24 * 60 * 60,        20, 100, 200],
           [365 * 24 * 60 * 60,         0,  60, 100],
           [2 * 365 * 24 * 60 * 60,     0,  30,  70],
           [4 * 365 * 24 * 60 * 60,     0,  10,  50],
           [8 * 365 * 24 * 60 * 60,     0,   0,  40],
           [100 * 365 * 24 * 60 * 60,   0,   0,   0],
          ];
  for(i=0;i<table.length-1;i++){
    var t1 = table[i][0];
    var t2 = table[i+1][0];
    if(t >= t1 && t <= t2){
      r = ((t - t1) * table[i+1][1] + (t2 - t) * table[i][1]) / (t2 - t1);
      r = Math.floor(r);
      if(r >= 256) r = 255;
      g = ((t - t1) * table[i+1][2] + (t2 - t) * table[i][2]) / (t2 - t1);
      g = Math.floor(g);
      if(g >= 256) g = 255;
      b = ((t - t1) * table[i+1][3] + (t2 - t) * table[i][3]) / (t2 - t1);
      b = Math.floor(b);
      if(b >= 256) b = 255;
      return "#" + hex2(r) + hex2(g) + hex2(b);
    }
  }
}

function addblankline(line,indent){
  editline = line;
  eline = line;
  deleteblankdata();
  for(var i=data.length-1;i>=editline;i--){
    data[i+1] = data[i];
  }
  var s = '';
  for(var i=0;i<indent;i++) s += ' ';
  data[editline] = s;
  search();
}

function mouseup(event){
  eline = -1;
}

function getMouseY(e){
  if(window.opera)                            //o6!)
      return e.clientY
  else if(document.all && document.getElementById && (document.compatMode=='CSS1Compat')) // e6
      return document.documentElement.scrollTop+event.clientY
  else if(document.all)                       //e4,e5,e6!)
      return document.body.scrollTop+event.clientY
  else if(document.layers||document.getElementById)
      return e.pageY                          //n4,n6,m1!)
}

var searchmode = false;

function mousedown(event){
  if(reloadTimeout) clearTimeout(reloadTimeout);
  reloadTimeout = setTimeout(reload,reloadInterval);

  y = getMouseY(event);
  if(y < 40){
    searchmode = true;
    return true;
  }
  searchmode = false;
  timemachine = false;

  editline = eline;
  calcdoi();
  display(true);
}

function indent(line){
    var s = data[line];
  var i;
  for(i=0;i<s.length-1 && s.substring(i,i+1)==' ';i++);
  return i;
}

function movelines(line){ // 移動する行数
  var i;
  var ind = indent(line);
  for(i=line+1;i<data.length && indent(i) > ind;i++);
  return i-line;
}

function destline_up(){
  var i;
  var ind = indent(editline);
  var found = false;
  var line;
  // インデントが自分と同じか自分より深い行を捜す。
  // ひとつもなければ -1 を返す。
  i = editline-1;
  while(true){
    if(indent(i) > ind){
      found = true;
      line = i;
    }
    if(indent(i) == ind) return i;
    if(indent(i) < ind) return found ? line : -1;
    i -= 1;
    if(i < 0) return found ? line : -1;
  }
}

function destline_down(){
  var i;
  var ind = indent(editline);
  var line;
  // インデントが自分と同じ行を捜す。
  // ひとつもなければ -1 を返す。
  i = editline+1;
  while(true){
    if(indent(i) == ind) return i;
    if(indent(i) < ind) return -1;
    i += 1;
    if(i >= data.length) return -1;
  }
}

function keyup(event){
  var kc = keycode(event);
  var sk = shiftkey(event);

  // 入力途中の文字列を確定 
  data[editline] = document.getElementById("newtext").value

  // 数秒入力がなければデータ書き込み
  if(!timemachine && !ctrlkey(event)){
    if(sk || (kc != KC.down && kc != KC.up && kc != KC.left && kc != KC.right)){
      if(timeout) clearTimeout(timeout);
      timeout = setTimeout("writedata()",2000);
  
      // 書き込みが必要な状態になると背景を黄色くしていたが、
      // ウザい気もするのでやめてみる。
      // var input = document.getElementById("newtext");
      // input.style.backgroundColor = "#ffff80";
    }
  }
}

function keydown(event){
  if(reloadTimeout) clearTimeout(reloadTimeout);
  reloadTimeout = setTimeout(reload,reloadInterval);

  var kc = keycode(event);
  //if(kc == KC.enter) event.preventDefault();  ************************************
  var sk = shiftkey(event);
  var i;
  var m,m2;
  var dst;
  var tmp = [];

  if(searchmode) return true;

  // 入力途中の文字列を確定 
  // data[editline] = document.getElementById("newtext").value
  //
  if(kc == KC.enter){
    query = document.getElementById("query");
    if(query) query.value = '';
    //
    // GM_POBoxが動いているときでも何故かEnterイベントが来てしまうので
    // このときは無視するようにしたい。
    // 苦しい解法だがなんとか動いている。
    //
// 単語帳ではEnterで行追加を行なわない
//    cand = document.getElementById('lexierra_cand_win');
//    if(!cand || cand.style.visibility != 'visible'){
//      addblankline(editline+1,indent(editline));
//      zoomlevel = 0;
//      calcdoi();
//      display();
//    }
  }
  if(kc == KC.down && sk){
    if(editline >= 0 && editline < data.length-1){
      m = movelines(editline);
      dst = destline_down();
      if(dst >= 0){
        m2 = movelines(dst);
        for(i=0;i<m;i++)  tmp[i] = data[editline+i];
        for(i=0;i<m2;i++) data[editline+i] = data[dst+i];
        for(i=0;i<m;i++)  data[editline+m2+i] = tmp[i];
	editline = editline + m2;
        deleteblankdata();
        display();
      }
    }
  }
  if(kc == KC.down && !sk){
    if(editline >= 0 && editline < data.length-1){
      var i;
      for(i=editline+1;i<data.length;i++){
        if(doi[i] >= -zoomlevel){
          editline = i;
          deleteblankdata();
          display();
          break;
        }
      }
    }
  }
  if(kc == KC.up && sk){
    if(editline > 0){
      m = movelines(editline);
      dst = destline_up();
      if(dst >= 0){
        m2 = editline-dst;
        for(i=0;i<m2;i++) tmp[i] = data[dst+i];
        for(i=0;i<m;i++)  data[dst+i] = data[editline+i]
        for(i=0;i<m2;i++) data[dst+m+i] = tmp[i];
        editline = dst;
        deleteblankdata();
        display();
      }
    }
  }
  if(kc == KC.up && !sk){
    if(editline > 0){
      var i;
      for(i=editline-1;i>=0;i--){
        if(doi[i] >= -zoomlevel){
          editline = i;
          deleteblankdata();
          display();
          break;
        }
      }
    }
  }
  if(kc == KC.tab && !sk || kc == KC.right && sk){
    if(editline >= 0 && editline < data.length){
      data[editline] = ' ' + data[editline];
      display();
    }
  }
  if(kc == KC.tab && sk || kc == KC.left && sk){
    if(editline >= 0 && editline < data.length){
      var s = data[editline]
      if(s.substring(0,1) == ' '){
        data[editline] = s.substring(1,s.length)
      }
      display();
    }
  }
  if(kc == KC.left && !sk && editline < 0){
    if(-zoomlevel < maxindent()){
      zoomlevel -= 1;
      display();
    }
  }
  if(kc == KC.right && !sk && editline < 0){
    if(zoomlevel < maxindent()){
      zoomlevel += 1;
      display();
    }
  }
  if(ctrlkey(event) && (/*kc == 0x56 || kc ==0x50 || */ kc == KC.left)){ // disable ctrl-V, ctrl-P
    timemachine = true;
    version += 1;
    getdata();
  }
  else if(ctrlkey(event) && (/* kc == 0x4e || */ kc == KC.right)){
    if(version > 0){
      version -= 1;
      if(version > 0){
        timemachine = true;
      }
      getdata();
    }
  }
  else if(kc >= 0x41 && kc <= 0x5A && editline < 0){
    if(!query){
      var querydiv = document.getElementById('querydiv');
      querydiv.innerHTML = 'Search: <input type="text" id="query" autocomplete="off" onkeyup="search(event)" style="font-size:10pt;border:none;padding:1px;margin:0;background-color:#f0f0ff;"><p>';
      query = document.getElementById("query");
    }
    
    query.style.visibility = 'visible';
    query.focus();
  }
}

function deleteblankdata(){ // 空白行を削除
  var reg = new RegExp('^ *$');
  for(i=0;i<data.length;i++){
    if(reg.exec(data[i])){
      data.splice(i,1);
    }
  }
  calcdoi();
}

// こうすると動的に関数を定義できるようだ
function linefunc(n){
  return function(event){
    seteditline(event,n);
  }
}

function setup(){
  name_id = MD5_hexhash(utf16to8(name));
  title_id = MD5_hexhash(utf16to8(title));
  var contents = document.getElementById('contents');
  var x,y;
  var i;
  for(i=0;i<1000;i++){
    y = document.createElement('div');
    y.id = "listbg" + i;
    x = document.createElement('span');
    x.id = "list" + i;
    x.onmousedown = linefunc(i);
    y.appendChild(x);
    contents.appendChild(y);
  }

  reloadTimeout = setTimeout(reload,reloadInterval);
}

function display(delay){
  // zoomlevelに応じてバックグラウンドの色を変える
  bgcolor = zoomlevel == 0 ? '#eeeeff' :
            zoomlevel == -1 ? '#e0e0c0' :
            zoomlevel == -2 ? '#c0c0a0' : '#a0a080';
  document.body.style.backgroundColor = bgcolor;
  if(version != 0){ // 古いページを表示する場合はバックグラウンド変更?
    // document.body.style.backgroundColor = '#c0c0c0';
  }

  var i;
  if(delay){ // ちょっと待ってもう一度呼び出す!
    setTimeout("display()",200);
    return;
  }

  var input = document.getElementById("newtext");
//  input.style.visibility = (editline == -1 ? 'hidden' : 'visible');
  if(editline == -1){
    deleteblankdata();

    input = document.getElementById("newtext");
    input.style.left = 0;
    input.style.top = 0;
    input.blur(); // フォーカスを解除

    // 何故かinputのフォーカスを解除するとqueryのフォーカスまで解除されてしまうので。
    query = document.getElementById("query");
    if(query) query.focus();

  }

  var contline = -1;
  for(i=0;i<data.length;i++){
//  for(i=data.length-1;i>=0;i--){
    var x;
    var ind;
    ind = indent(i);
    xmargin = ind * 30;
    var s;
    var head;
    head = headchar[indent(i)];
    if(!head) head = '';
    else head += ' ';
    s = head + data[i];

    var t = document.getElementById("list"+i);
    t.style.position = '';
    t.innerHTML = '&nbsp;'; // 何故かこういうのを入れないと、下向き矢印で項目移動したときレイアウトがずれる。
    if(doi[i] >= -zoomlevel){
      if(i == editline){
        t.style.lineHeight = input.offsetHeight + 'px';
        t.style.visibility = 'hidden';
        t.parentNode.style.visibility = 'hidden';

        input.style.left = xmargin+25;
        input.style.top = t.offsetTop-1;
        input.value = data[i];
        input.onmousedown = linefunc(i);
        input.focus(); // IEで動かない
      }
      else {
        var lastchar = '';
        if(i > 0) lastchar = data[i-1][data[i-1].length-1];
	//if(editline == -1 && (lastchar == ' ' || lastchar == '\\')){
	if(editline == -1 && lastchar == '\\'){
          if(contline < 0) contline = i-1;
          var tcont = document.getElementById("list"+contline);
	  s = tcont.innerHTML
	  if(s[s.length-1] == '\\') s = s.substr(0,s.length-1);
          tcont.innerHTML = s + tag(data[i]);

          t.style.visibility = 'hidden';
          t.style.lineHeight = 0;

          p = t.parentNode;
          p.className = 'listedit' + ind;
          p.style.visibility = 'hidden';
          p.style.lineHeight = 0;
        }
        else {
          contline = -1;
          t.style.visibility = 'visible';
          t.style.lineHeight = '';
	  s = tag(data[i]);
	  //if(s[s.length-1] == '\\') s = s.substr(0,s.length-1);
          t.innerHTML = s;
          t.style.margin.x = xmargin;

          p = t.parentNode;
          p.className = 'listedit' + ind;
          p.style.visibility = 'visible';
          p.style.position = '';
          p.style.lineHeight = '';
          p.style.margin.x = xmargin;
        }
      }
    }
    else {
      t.style.visibility = 'hidden';
      t.innerHTML = '';
      t.style.position = 'absolute';
      t.style.left = 0;
      t.style.top = 0;

      p = t.parentNode;
      p.style.visibility = 'hidden';
      p.style.position = 'absolute';
      p.style.left = 0;
      p.style.top = 0;
    }

    t = document.getElementById("listbg"+i);
    if(version > 0){
      t.style.backgroundColor = bgcol(dt[i]);
    }
    else {
      t.style.background = 'transparent';
    }
  }
  for(i=data.length;i<1000;i++){
    var t = document.getElementById("list"+i);
    t.style.visibility = 'hidden';
    t = document.getElementById("listbg"+i);
    t.style.visibility = 'hidden';
  }

  for(i=data.length;i<1000;i++){
    t = document.getElementById("list"+i);
    t.innerHTML = '';
    t.style.position = 'absolute';
    t.style.left = 0;
    t.style.top = 0;
    t.style.visibility = 'hidden';
  }

  input.style.visibility = (editline == -1 ? 'hidden' : 'visible');
}

function seteditline(event,i){
  eline = i;
  var sk = shiftkey(event)
  if(sk){
    addblankline(i+1,indent(i));  // 単語帳の場合下に行を追加
  }
  else {
//    deleteblankdata();
  }
}

function tag(s){
  var s1,s2,s3;
  s = s.replace(/[\r\n]+/,'');
  while(s.match(/^(.*)<(.*)$/)){
    s1 = RegExp.$1;
    s2 = RegExp.$2;
    s = s1 + '&lt;' + s2;
  }
//  while(s.match(/^(.*)\[\[\[([^\]]*)\]\]\](.*)$/)){
//    s1 = RegExp.$1;
//    s2 = RegExp.$2;
//    s3 = RegExp.$3;
//    s = s1 + '<b>' + s2 + '</b>' + s3;
//  }
  while(a = s.match(/^(.*)\[\[\[(([^\]]|\][^\]]|[^\]]\])*)\]\]\](.*)$/)){
    s1 = RegExp.$1;
    s2 = RegExp.$2;
    s3 = RegExp.$4;
    if(s2.match(/^(http[^ ]+) (.*)\.(jpg|jpeg|jpe|png|gif)$/i)){
      s4 = RegExp.$1;
      s5 = RegExp.$2;
      s6 = RegExp.$3;
      s = s1 + '<a href="' + s4 + '"><img src="' + s5 + '.' + s6 + '" border="none" height=80></a>' + s3;
    }
    else if(s2.match(/^(http.+)\.(jpg|jpeg|jpe|png|gif)$/i)){
      s4 = RegExp.$1;
      s5 = RegExp.$2;
      s = s1 + '<a href="' + s4 + '.' + s5 + '"><img src="' + s4 + '.' + s5 + '" border="none" height=80></a>' + s3;
    }
    else {
      s = s1 + '<b>' + s2 + '</b>' + s3;
    }
  }
  while(a = s.match(/^(.*)\[\[(([^\]]|\][^\]]|[^\]]\])*)\]\](.*)$/)){
    s1 = RegExp.$1;
    s2 = RegExp.$2;
    s3 = RegExp.$4;
    if(s2.match(/^([a-fA-F0-9]{32})\.(\w+) (.*)\.(jpg|jpeg|jpe|png|gif)$/i)){ // (MD5).ext をpitecan.com上のデータにリンク (2010 5/11)
      md5 = RegExp.$1;
      ext = RegExp.$2;
      image = RegExp.$3;
      imageext = RegExp.$4;
      s = s1 + '<a href="http://masui.sfc.keio.ac.jp/' + md5 + '.' + ext + '"><img src="' + image + '.' + imageext + '" border="none"></a>' + s3;
      //s = s1 + '<a href="http://pitecan.com/' + md5 + '.' + ext + '"><img src="' + image + '.' + imageext + '" border="none"></a>' + s3;
    }
    else if(s2.match(/^(http[^ ]+) (.*)\.(jpg|jpeg|jpe|png|gif)$/i)){
      s4 = RegExp.$1;
      s5 = RegExp.$2;
      s6 = RegExp.$3;
      s = s1 + '<a href="' + s4 + '"><img src="' + s5 + '.' + s6 + '" border="none"></a>' + s3;
    }
    else if(s2.match(/^(http.+)\.(jpg|jpeg|jpe|png|gif)$/i)){
      s4 = RegExp.$1;
      s5 = RegExp.$2;
      s = s1 + '<a href="' + s4 + '.' + s5 + '"><img src="' + s4 + '.' + s5 + '" border="none"></a>' + s3;
    }
    else if(s2.match(/^(http[^ ]+) (.*)$/)){
      s4 = RegExp.$1;
      s5 = RegExp.$2;
      s = s1 + '<a href="' + s4 + '">' + s5 + '</a>' + s3;
    }
    else if(s2.match(/^(http[s]?:[^: ]+)$/)){
      s4 = RegExp.$1;
      s = s1 + '<a href="' + s4 + '" class="link">' + s4 + '</a>' + s3;
    }
    else if(s2.match(/^(http[s]?:.*):(.*)$/)){
    	s4 = RegExp.$1;
    	s5 = RegExp.$2;
    	s = s1 + '<a href="' + s4 + '/' + s5 + '" class="tag">' + s5 + '</a>' + s3;
    	addtag(s2);
    }
    else if(s2.match(/^((\d\d\d\d)(\d\d)(\d\d)(\d\d\d\d\d\d))\.(\S+)$/)){
	timeid = RegExp.$1;
	year = RegExp.$2;
	month = RegExp.$3;
	day = RegExp.$4;
	ext = RegExp.$6;
	imonth = month;
	if(imonth.match(/^0(.)/)) imonth = RegExp.$1;
	iday = day;
	if(iday.match(/^0(.)/)) iday = RegExp.$1;
	url = "http://pitecan.com/~masui/PIM/" + year + "/" + imonth + "/" + iday + "/" + timeid + "." + ext;
	s = s1 + '<a href="' + url + '" class="link">' + s2 + '</a>' + s3;
	addtag(s2);
    }
    else if(s2.match(/^((\d\d\d\d)(\d\d)(\d\d)(\d\d\d\d\d\d))\.(\S+) (.*)$/)){
	timeid = RegExp.$1;
	year = RegExp.$2;
	month = RegExp.$3;
	day = RegExp.$4;
	ext = RegExp.$6;
	tmptitle = RegExp.$7
	imonth = month;
	if(imonth.match(/^0(.)/)) imonth = RegExp.$1;
	iday = day;
	if(iday.match(/^0(.)/)) iday = RegExp.$1;
	url = "http://pitecan.com/~masui/PIM/" + year + "/" + imonth + "/" + iday + "/" + timeid + "." + ext;
        if(tmptitle.match(/^(.*)\.(jpg|jpeg|jpe|png|gif)$/i)){
          s4 = RegExp.$1;
          s5 = RegExp.$2;
          s = s1 + '<a href="' + url + '" class="link"><img src="' + s4 + '.' + s5 + '" border="none"></a>' + s3;
        }
        else {
          s = s1 + '<a href="' + url + '" class="link">' + tmptitle + '</a>' + s3;
        }
	addtag(s2);
    }
    else if(s2.match(/^([a-fA-F0-9]{32})\.(\w+) (.*)$/)){ // (MD5).ext をpitecan.com上のデータにリンク (2010 5/1)
	md5 = RegExp.$1;
	ext = RegExp.$2;
	comment = RegExp.$3;
        s = s1 + '<a href="http://masui.sfc.keio.ac.jp/' + md5 + '.' + ext + '" class="link">' + comment + '</a>' + s3;
        //s = s1 + '<a href="http://pitecan.com/' + md5 + '.' + ext + '" class="link">' + comment + '</a>' + s3;
    }
    else if(s2.match(/^@([a-zA-Z0-9_]+)$/)){ // @名前 を twitterへのリンクにする (2010 4/27)
        twittername = RegExp.$1
        s = s1 + '<a href="http://twitter.com/' + twittername + '" class="link">@' + twittername + '</a>' + s3;
    }
    else if(s2.match(/^(.+)::(.+)$/)){ //  Wikiname::Title で他Wikiに飛ぶ (2010 4/27)
       wikiname = RegExp.$1;
       wikititle = RegExp.$2;
       wikiurl = root + '/' + wikiname + '/';
       url = root + '/' + wikiname + '/' + encodeURIComponent(wikititle).replace(/%2F/g,"/");
       // s = s1 + '<a href="' + url + '" class="link">' + wikiname + '::' + wikititle + '</a>' + s3; このリンクは五月蝿い...
       // s = s1 + '<a href="' + url + '" class="link" title="' + wikiname + '::' + wikititle + '">' + '[' + wikititle + ']</a>' + s3;
       s = s1 + '<a href="' + wikiurl + '" class="link" title="' + wikiname + '">' + wikiname + '</a>::<a href="' + url + '" class="link" title="' + wikititle + '">' + wikititle + '</a3>' + s3;
    }
    else { // タグ/リンク
	s = s1 + '<a href="' + root + '/' + name + '/' + encodeURIComponent(s2).replace(/%2F/g,"/") + '" class="tag">' + s2 + '</a>' + s3;
      addtag(s2);
    }
  }
  //  alert(s);
  return s;
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

function addtag(tag){
}

function writedata(){
  xmlhttp = createXmlHttp();
  xmlhttp.open("POST", root + "/post" , true);
  xmlhttp.setRequestHeader("Content-Type" , "application/x-www-form-urlencoded"); // これで送るとSinatraが受け付けるらしい
  //http://www.gittr.com/index.php/archive/getting-data-into-a-sinatra-app に解説あり
  //xmlhttp.setRequestHeader("Content-Type" , "text/html; charset=utf-8"); //2006/11/10追加 for Safari

  //postdata = "data=" + encodeURIComponent(name + "\n" + title + "\n" + orig_md5 + "\n" + data.join("\n"));
  datastr = data.join("\n");

//datamd5 = MD5_hexhash(utf16to8(datastr));
//alert(datamd5);

  postdata = "data=" + encodeURIComponent(name + "\n" + title + "\n" + orig_md5 + "\n" + datastr)

  xmlhttp.send(postdata);
  xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState==4) {
      response = xmlhttp.responseText;
  alert(response);
      iff(response == 'conflict'){
        // 再読み込み
        getdata();
      }
      else {
        orig_md5 = MD5_hexhash(utf16to8(datastr));
      }
    }
  }

  var input = document.getElementById("newtext");
  input.style.backgroundColor = "#ddd";
}

function getdata(){ // 20050815123456.utf のようなテキストを読み出し
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
      orig_md5 = MD5_hexhash(utf16to8(data.join("\n")));
      //alert(MD5_hexhash(utf16to8(data.join("\n"))));
      search();
    }
  }
  xmlhttp.send("");
}

function maxindent()
{
  var max = 0;
  var ind;
  for(var i=0;i<data.length;i++){
    ind = indent(i);
    if(ind > max) max = ind;
  }
  return max;
}

function calcdoi(){
  var q = document.getElementById("query");
  var pbs = new POBoxSearch(assocwiki_pobox_dict);
  var re = null;
  if(q && q.value != '') re = pbs.regexp(q.value,false);

  var maxind = maxindent();

  for(var i=0;i<data.length;i++){
    matched = (re ? re.exec(data[i]) : true);
    if(matched){
      doi[i] = maxind - indent(i);
    }
    else {
      doi[i] = 0 - indent(i) - 1;
    }
  }
}

function search(event)
{
  var kc;
  if(event) kc = keycode(event);
  if(event == null || kc != KC.down && kc != KC.up && kc != KC.left && kc != KC.right){
    calcdoi();
    zoomlevel = 0;
    display();
  }
  return false;
}

function addimageline(line,indent,id){
  editline = line;
  eline = line;
  deleteblankdata();
  for(var i=data.length-1;i>=editline;i--){
    data[i+1] = data[i];
  }
  var s = '';
  for(var i=0;i<indent;i++) s += ' ';
  s += '[[http://gyazo.com/' + id + '.png]]';
  data[editline] = s;
  search();
}

function addimage(id)
{
  var old = editline;
  if(data[0] == '(empty)'){
    data[0] = '[[http://gyazo.com/' + id + '.png]]';
  }
  else {
    editline = data.length-1;
    addimageline(editline+1,indent(editline),id);
  }
  writedata();
  editline = -1;
  display();
  editline = old;
}

//setup();
//getdata();

// 最新のページに更新
function reload()
{
    version = 0;
    getdata();
    display();
    reloadTimeout = setTimeout(reload,reloadInterval);
}
