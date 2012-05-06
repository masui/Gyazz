//
// jQueryを利用して書き直したもの (2011/6/11)
// 

// 
//  以下の編集はSinatraでセットされる
//  var name =  '増井研';
//  var title = 'MIRAIPEDIA';
//  var root =  'http://masui.sfc.keio.ac.jp/Gyazz';
//  var version = 0;

var name_id;
var title_id;

var editline = -1;
var eline = -1;

var data = [];
var dt = [];          // 背景色
var doi = [];
var zoomlevel = 0;
var spaces = [];

var posy = [];

var datestr = '';

var sendTimeout;                     // 放置すると書き込み
var reloadTimeout = null;            // 放っておくとリロードするように
var reloadInterval = 10 * 60 * 1000; // 10分ごとにリロード

var searchmode = false;

var edited = false;

var orig_md5; // getdata()したときのMD5

var KC = {
    tab:9, enter:13, ctrlD:17, left:37, up:38, right:39, down:40
};

var authbuf = [];

//$(document).ready(function(){
//	$('#rawdata').hide();
//	setup();
//	getdata();
//    })
    
// keypressを定義しておかないとFireFox上で矢印キーを押してときカーソルが動いてしまう
$(document).keypress(function(event){
	var kc = event.which;
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
	if(!event.shiftKey && (kc == KC.down || kc == KC.up || kc == KC.tab)){
	    return false;
	}
    });

function hex2(v){
    return ("0" + v.toString(16)).slice(-2);
}

function bgcol(t){
    // データの古さに応じて行の色を変える
    var table = [
		 [0,                                  256,256,256],
		 [10,                                 240,240,240],
		 [10*10,                              220,220,220],
		 [10*10*10,                           200,200,200],
		 [10*10*10*10,                        180,180,180],
		 [10*10*10*10*10,                     160,160,160],
		 [10*10*10*10*10*10,                  140,140,140],
		 [10*10*10*10*10*10*10,               120,120,120],
		 [10*10*10*10*10*10*10*10,            100,100,100],
		 [10*10*10*10*10*10*10*10*10,          80, 80, 80],
		 [10*10*10*10*10*10*10*10*10*10,       60, 60, 60],
		 [10*10*10*10*10*10*10*10*10*10*10,    40, 40, 40],
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

$(document).mouseup(function(event){
	eline = -1;
    });

$(document).mousedown(function(event){
	if(reloadTimeout) clearTimeout(reloadTimeout);
	reloadTimeout = setTimeout(reload,reloadInterval);
	
	y = event.pageY;
	if(y < 40){
	    searchmode = true;
	    return true;
	}
	searchmode = false;
	editline = eline;
	calcdoi();
	display(true);
    });

function indent(line){ // 先頭の空白文字の数
    return data[line].match(/^( *)/)[1].length;
}

function movelines(line){ // 移動すべき行数
    var i;
    var ind = indent(line);
    for(i=line+1;i<data.length && indent(i) > ind;i++);
    return i-line;
}

function destline_up(){
    // インデントが自分と同じか自分より深い行を捜す。
    // ひとつもなければ -1 を返す。
    var ind_editline = indent(editline);
    var foundline = -1;
    for(var i=editline-1;i>=0;i--){
	ind = indent(i);
	if(ind > ind_editline){
	    foundline = i;
	}
	if(ind == ind_editline) return i;
	if(ind < ind_editline) return foundline;
    }
    return foundline;
}

function destline_down(){
    // インデントが自分と同じ行を捜す。
    // ひとつもなければ -1 を返す。
    var ind_editline = indent(editline);
    for(var i=editline+1;i<data.length;i++){
	ind = indent(i);
	if(ind == ind_editline) return i;
	if(ind < ind_editline) return -1;
    }
    return -1;
}

$(document).keyup(function(event){
	var kc = event.which;
	var sk = event.shiftKey;
	
	// 入力途中の文字列を確定 
	data[editline] = $("#newtext").val();
	
	// 数秒入力がなければデータ書き込み
	if(version == 0 && !event.ctrlKey && edited){
	    if(sk || (kc != KC.down && kc != KC.up && kc != KC.left && kc != KC.right)){
		if(sendTimeout) clearTimeout(sendTimeout);
		sendTimeout = setTimeout("writedata()",1300);
		$("#newtext").css('background-color','#f0f0d0');
	    }
	}
    });

$(document).keydown(function(event){
	if(reloadTimeout) clearTimeout(reloadTimeout);
	reloadTimeout = setTimeout(reload,reloadInterval);
	
	var kc = event.which;
	var sk = event.shiftKey;
	var ck = event.ctrlKey;
	var i;
	var m,m2;
	var dst;
	var tmp = [];

	if(searchmode) return true;

	edited = false;
	
	if(kc == KC.enter){
	    $('#query').val('');
	}
	if(kc == KC.down && sk){ // Shift+↓ = 下にブロック移動
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
		    edited = true;
		}
	    }
	}
	if(kc == KC.down && !sk){ // ↓ = カーソル移動
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
	if(kc == KC.up && sk){ // 上にブロック移動
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
		    edited = true;
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
	if(kc == KC.tab && !sk || kc == KC.right && sk){ // indent
	    if(editline >= 0 && editline < data.length){
		data[editline] = ' ' + data[editline];
		display();
	    }
	}
	if(kc == KC.tab && sk || kc == KC.left && sk){ // undent
	    if(editline >= 0 && editline < data.length){
		var s = data[editline]
		    if(s.substring(0,1) == ' '){
			data[editline] = s.substring(1,s.length)
		    }
		display();
	    }
	}
	if(kc == KC.left && !sk && !ck && editline < 0){ // zoom out
	    if(-zoomlevel < maxindent()){
		zoomlevel -= 1;
		display();
	    }
	}
	if(kc == KC.right && !sk && !ck && editline < 0){ // zoom in
	    //if(zoomlevel < maxindent()){
	    if(zoomlevel < 0){
		zoomlevel += 1;
		display();
	    }
	}
	if(ck && kc == KC.left){ // 古いバージョンゲット
	    version += 1;
	    getdata();
	}
	else if(ck && kc == KC.right){
	    if(version > 0){
		version -= 1;
		getdata();
	    }
	}
	else if(kc >= 0x30 && kc <= 0x7e && editline < 0){
	    $('#querydiv').css('visibility','visible').css('display','block');
	    $('#query').focus();
	}
	//else if(kc >= 0x20 && kc <= 0x7e || kc == 0x08 || (ck && kc == 0x68)){
	else if(ck && kc == 0x68){
	    edited = true;
	}
	else if(kc == 0x08){
	    edited = true;
	}
	else if(ck){
	    edited = false;
	}
	else {
	    edited = true;
	}
    });

function deleteblankdata(){ // 空白行を削除
    for(i=0;i<data.length;i++){
	if(data[i].match(/^ *$/)){
	    data.splice(i,1);
	}
    }
    calcdoi();
}

// 認証文字列をサーバに送る
function tell_auth(){
    authstr = authbuf.sort().join(",");
    postdata = "data=" + encodeURIComponent(name + "\n" + title + "\n" + authstr);
    $.ajax({
        type: "POST",
	async: true,
	url: root + "/__tellauth",
	data: postdata
    })
}

// こうすると動的に関数を定義できる (クロージャ)
// 行をクリックしたとき呼ばれる
function linefunc(n){
    return function(event){
	if(write_authorized){
	    eline = n;
	}
	if(do_auth){
	    authbuf.push(data[n]);
	    tell_auth();
	}
	if(event.shiftKey){
	    addblankline(n,indent(n));  // 上に行を追加
	}
    }
}

function setup(){ // 初期化
    name_id = MD5_hexhash(utf16to8(name));
    title_id = MD5_hexhash(utf16to8(title));
    // <div id='listbg0'>
    //   <span id='list0'>
    for(var i=0;i<1000;i++){
	var y = $('<div>').attr('id','listbg'+i);
	var x = $('<span>').attr('id','list'+i).mousedown(linefunc(i));
	$('#contents').append(y.append(x));
    }
    reloadTimeout = setTimeout(reload,reloadInterval);
    
    $('#querydiv').css('display','none');
}

function display(delay){
    // zoomlevelに応じてバックグラウンドの色を変える
    var bgcolor = zoomlevel == 0 ? '#eeeeff' :
	zoomlevel == -1 ? '#e0e0c0' :
	zoomlevel == -2 ? '#c0c0a0' : '#a0a080';
    $("body").css('background-color',bgcolor);
    $('#datestr').text(datestr);
    $('#title').attr('href',root + "/" + name + "/" + title + "/" + "__edit" + "/" + version);
    
    var i;
    if(delay){ // ちょっと待ってもう一度呼び出す!
	setTimeout("display()",200);
	return;
    }
    
    var input = $("#newtext");
    if(editline == -1){
	deleteblankdata();
	input.css('display','none');
    }
    
    var contline = -1;
    if(data.length == 0){
	data = ["(empty)"];
	doi[0] = maxindent();
    }
    for(i=0;i<data.length;i++){
	var x;
	var ind;
	ind = indent(i);
	xmargin = ind * 30;
	
	var t = $("#list"+i);
	var p = $("#listbg"+i);
	if(doi[i] >= -zoomlevel){
	    if(i == editline){ // 編集行
		t.css('display','inline').css('visibility','hidden');
		p.css('display','block').css('visibility','hidden');
		input.css('position','absolute').css('visibility','visible').css('left',xmargin+25).css('top',p.position().top).val(data[i]).mousedown(linefunc(i));
		setTimeout(function(){ $("#newtext").focus(); }, 100); // 何故か少し待ってからfocus()を呼ばないとフォーカスされない...
	    }
	    else {
		var lastchar = '';
		if(i > 0) lastchar = data[i-1][data[i-1].length-1];
		if(editline == -1 && lastchar == '\\'){ // 継続行
		    if(contline < 0) contline = i-1;
		    s = '';
		    for(var j=contline;j<=i;j++){
			s += data[j].replace(/\\$/,'__newline__');
		    }
		    $("#list"+contline).css('display','inline').css('visibility','visible').html(tag(s,contline).replace(/__newline__/g,''));
		    $("#listbg"+contline).css('display','inline').css('visibility','visible');
		    //t.css('display','none');
		    //p.css('display','none');
		    t.css('visibility','hidden');
		    p.css('visibility','hidden');
		}
		else { // 通常行
		    contline = -1;
		    if(m = data[i].match(/\[\[(https:\/\/gist\.github\.com.*\?.*)\]\]/i)){ // gistエンベッド
			// https://gist.github.com/1748966 のやり方
			var gisturl = m[1];
			var gistFrame = document.createElement("iframe");
			gistFrame.setAttribute("width", "100%");
			gistFrame.id = "gistFrame" + i;
			gistFrame.style.border = 'none';
			gistFrame.style.margin = '0';
			t.children().remove(); // 子供を全部消す
			t.append(gistFrame);
			var gistFrameHTML = '<html><body onload="parent.adjustIframeSize(document.body.scrollHeight,'+i+
			    ')"><scr' + 'ipt type="text/javascript" src="' + gisturl + '"></sc'+'ript></body></html>';
			// Set iframe's document with a trigger for this document to adjust the height
			var gistFrameDoc = gistFrame.document;
			if (gistFrame.contentDocument) {
			    gistFrameDoc = gistFrame.contentDocument;
			} else if (gistFrame.contentWindow) {
			    gistFrameDoc = gistFrame.contentWindow.document;
			}

			gistFrameDoc.open();
			gistFrameDoc.writeln(gistFrameHTML);
			gistFrameDoc.close(); 

			//			t.css('display','block');
			//			p.css('display','block');
		    }
		    else {
			t.css('display','inline').css('visibility','visible').css('line-height','').html(tag(data[i],i));
			p.attr('class','listedit'+ind).css('display','block').css('visibility','visible').css('line-height','');
		    }
		}
	    }
	}
	else {
	    t.css('display','none');
	    p.css('display','none');
	}
	
	// 各行のバックグラウンド色設定
	$("#listbg"+i).css('background-color',version > 0 ? bgcol(dt[i]) : 'transparent');
    }
    
    for(i=data.length;i<1000;i++){
	$('#list'+i).css('display','none');
	$('#listbg'+i).css('display','none');
    }
    
    input.css('display',(editline == -1 ? 'none' : 'block'));

    /*    
    for(i=0;i<data.length;i++){
	//posy[i] = $('#list'+i).position().top;
	posy[i] = $("#e" + i + "_0").offset().top;
    }
    for(i=0;i<data.length;i++){
    	for(var j=0;j<=spaces[i];i++){
    	    $("#e" + i + "_" + j).css('position','absolute').css('top',posy[line]);
    	}
    }
    */
    aligncolumns();

    // リファラを消すプラグイン
    // http://logic.moo.jp/memo.php/archive/569
    // http://logic.moo.jp/data/filedir/569_3.js
    //
    jQuery.kill_referrer.rewrite.init();
}



function adjustIframeSize(newHeight,i) {
    var frame= document.getElementById("gistFrame"+i);
    frame.style.height = parseInt(newHeight) + "px";
    console.log("size adjusted", newHeight);
}

function aligncolumns(){ // 同じパタンの連続を検出して桁を揃える
    var i;
    var beginline = 0;
    var lastspaces = -1;
    var lastindent = -1;
    for(i=0;i<data.length;i++){
	if(spaces[i] > 0 && spaces[i] == lastspaces && indent(i) == lastindent){ // cont
	}
	else {
	    if(lastspaces > 1 && i-beginline > 1){ // 同じパタンの連続を検出
		align(beginline,i-beginline);
	    }
	    beginline = i;
	}
	lastspaces = spaces[i];
	lastindent = indent(i);
    }
    if(lastspaces > 1 && i-beginline > 1){ //  同じパタンの連続を検出
	align(beginline,i-beginline);
    }
}

function align(begin,lines){ // begin番目からlines個の行を桁揃え
    var pos = [];
    var width = [];
    var maxwidth = [];
    for(var line=begin;line<begin+lines;line++){ // 表示されている要素の位置を取得
	pos[line] = [];
	width[line] = [];
	for(var i=0;i<=spaces[begin];i++){
	    var id = "#e" + line + "_" + (i + indent(line));
	    pos[line][i] = $(id).offset().left;
	}
	for(var i=0;i<spaces[begin];i++){
	    width[line][i] = pos[line][i+1]-pos[line][i];
	}
    }
    for(var i=0;i<spaces[begin];i++){ // 桁ごとに最大幅を計算
	var max = 0;
	for(var line=begin;line<begin+lines;line++){
	    if(width[line][i] > max) max = width[line][i];
	}
	maxwidth[i] = max;
    }
    var colpos = pos[begin][0];
    for(var i=0;i<=spaces[begin];i++){ // 最大幅ずつずらして表示
	for(var line=begin;line<begin+lines;line++){
	    var id = "#e" + line + "_" + (i + indent(line));
	    $(id).css('position','absolute').css('line-height','').css('left',colpos); // .css('top',posy[line]);
	    //$("#listbg"+line).css('line-height','');
	}
	colpos += maxwidth[i];
    }
}

function tag(s,line){
    matched = [];
    s = s.replace(/</g,'&lt;');
    while(m = s.match(/^(.*)\[\[\[(([^\]]|\][^\]]|[^\]]\])*)\]\]\](.*)$/)){ // [[[....]]]
	pre =   m[1];
	inner = m[2];
	post =  m[4];
	//if(t = inner.match(/^(http[^ ]+) (.*)\.(jpg|jpeg|jpe|png|gif)$/i)){ // [[[http:... ....jpg]]]
	//    matched.push('<a href="' + t[1] + '"><img src="' + t[2] + '.' + t[3] + '" border="none" target="_blank" height=80></a>');
	//}
	if(t = inner.match(/^(http[^ ]+) (.*)\.(jpg|jpeg|jpe|png|gif)/i)){ // [[[http:... ....jpg]]]
	    matched.push('<a href="' + t[1] + '"><img src="' + t[2] + '.' + t[3] + '" border="none" target="_blank" height=80></a>');
	}
	else if(t = inner.match(/^(http.+)\.(jpg|jpeg|jpe|png|gif)/i)){ // [[[http...jpg]]]
	    matched.push('<a href="' + t[1] + '.' + t[2] + '" target="_blank"><img src="' + t[1] + '.' + t[2] + '" border="none" height=80></a>');
	}
	else { // [[[abc]]]
	    matched.push('<b>' + inner + '</b>');
	}
	s = pre + '<<<' + (matched.length-1) + '>>>' + post;
    }
    while(m = s.match(/^(.*)\[\[(([^\]]|\][^\]]|[^\]]\])*)\]\](.*)$/)){ // [[....]]
	pre =   m[1];
	inner = m[2];
	post =  m[4];
	if(t = inner.match(/^(http[^ ]+) (.*)\.(jpg|jpeg|jpe|png|gif)$/i)){ // [[http://example.com/ http://example.com/abc.jpg]]
	    matched.push('<a href="' + t[1] + '" target="_blank"><img src="' + t[2] + '.' + t[3] + '" border="none"></a>');
	}
	else if(t = inner.match(/^(http.+)\.(jpg|jpeg|jpe|png|gif)$/i)){ // [[http://example.com/abc.jpg]
	    matched.push('<a href="' + t[1] + '.' + t[2] + '" target="_blank"><img src="' + t[1] + '.' + t[2] + '" border="none"></a>');
	}
	else if(t = inner.match(/^((http[s]?|javascript):[^ ]+) (.*)$/)){ // [[http://example.com/ example]]
	    matched.push('<a href="' + t[1] + '" target="_blank">' + t[3] + '</a>');
	}
        else if(t = inner.match(/^((http[s]?|javascript):[^ ]+)$/)){ // [[http://example.com/]]
	    matched.push('<a href="' + t[1] + '" class="link" target="_blank">' + t[1] + '</a>');
	}
	else if(t = inner.match(/^@([a-zA-Z0-9_]+)$/)){ // @名前 を twitterへのリンクにする
	    matched.push('<a href="http://twitter.com/' + t[1] + '" class="link" target="_blank">@' + t[1] + '</a>');
	}
	else if(t = inner.match(/^(.+)::$/)){ //  Wikiname:: で他Wikiに飛ぶ (2011 4/17)
	    matched.push('<a href="' + root + '/' + t[1] + '" class="link" target="_blank" title="' + t[1] + '">' + t[1] + '</a>');
	}
	else if(t = inner.match(/^(.+):::(.+)$/)){ //  Wikiname:::Title で他Wikiに飛ぶ (2010 4/27)
	    wikiname = t[1];
	    wikititle = t[2];
	    url = root + '/' + wikiname + '/' + encodeURIComponent(wikititle).replace(/%2F/g,"/");
	    matched.push('<a href="' + url + '" class="link" target="_blank" title="' + wikititle + '">' + wikititle + '</a>');
	}
	else if(t = inner.match(/^(.+)::(.+)$/)){ //  Wikiname::Title で他Wikiに飛ぶ (2010 4/27)
	    wikiname = t[1];
	    wikititle = t[2];
	    wikiurl = root + '/' + wikiname + '/';
	    url = root + '/' + wikiname + '/' + encodeURIComponent(wikititle).replace(/%2F/g,"/");
	    matched.push('<a href="' + wikiurl + '" class="link" target="_blank" title="' + wikiname + '">' + wikiname +
			 '</a>::<a href="' + url + '" class="link" target="_blank" title="' + wikititle + '">' + wikititle + '</a>');
	}
	else if(t = inner.match(/^([a-fA-F0-9]{32})\.(\w+) (.*)$/)){ // (MD5).ext をpitecan.com上のデータにリンク (2010 5/1)
	    matched.push('<a href="http://masui.sfc.keio.ac.jp/' + t[1] + '.' + t[2] + '" class="link">' + t[3] + '</a>');
	}
	else {
	    matched.push('<a href="' + root + '/' + name + '/' + inner + '" class="tag" target="_blank">' + inner + '</a>');
	}
	s = pre + '<<<' + (matched.length-1) + '>>>' + post;
    }
    elements = s.split(/ /);
    spaces[line] = elements.length - indent(line) - 1;
    for(i=0;i<elements.length;i++){
	while(a = elements[i].match(/^(.*)<<<(\d+)>>>(.*)$/)){
	    elements[i] = a[1] + matched[a[2]] + a[3];
	}
    }
    for(i=0;i<elements.length;i++){
	elements[i] = "<span id='e"+line+'_'+i+"'>" + elements[i] + "</span>";
    }
    return elements.join(' ');
}

function writedata(){
    if(!write_authorized) return;
    datastr = data.join("\n").replace(/\n+$/,'')+"\n";
    postdata = "data=" + encodeURIComponent(name + "\n" + title + "\n" + orig_md5 + "\n" + datastr);
    $.ajax({
	    type: "POST",
	    async: true,
	    url: root + "/__write",
	    data: postdata,
	    success: function(msg){
		$("#newtext").css('background-color','#ddd');
		if(msg.match(/^conflict/)){
		    // 再読み込み
		    getdata(); // ここで強制書き換えしてしまうのがマズい? (2011/6/17)
		}
		else if(msg == 'protected'){
		    // 再読み込み
		    alert("このページは編集できません");
		    getdata();
		    }
		    else {
			orig_md5 = MD5_hexhash(utf16to8(datastr));
		    }
		}
	    })
	}

function getdata(){ // 20050815123456.utf のようなテキストを読み出し
    $.ajax({
	    async: false,
		url: root + "/" + name + "/" + title + "/text/" + version,
		success: function(msg){
		d = msg.split(/\n/);
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
		orig_md5 = MD5_hexhash(utf16to8(data.join("\n").replace(/\n+$/,'')+"\n"));
		search();
	    }
	});
}

function maxindent(){
    var maxind = 0;
    for(var i=0;i<data.length;i++){
	var ind = indent(i);
	if(ind > maxind) maxind = ind;
    }
    return maxind;
}

function calcdoi(){
    var q = document.getElementById("query");
    var pbs = new POBoxSearch(assocwiki_pobox_dict);
    var re = null;
    if(q && q.value != '') re = pbs.regexp(q.value,false);

    var maxind = maxindent();
    for(var i=0;i<data.length;i++){
	if(re ? re.exec(data[i]) : true){
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
    if(event) kc = event.which;
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

// 最新のページに更新
function reload()
{
    version = 0;
    getdata();
    // display(); getdata()で呼ばれるはず
    if(reloadTimeout) clearTimeout(reloadTimeout);
    reloadTimeout = setTimeout(reload,reloadInterval);
}
