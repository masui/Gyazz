//
// jQueryを利用して書き直したもの (2011/6/11)
// 

// 
//  以下の編集はSinatraでセットされる
//  var name =  '増井研';
//  var title = 'MIRAIPEDIA';
//  var root =  'http://masui.sfc.keio.ac.jp/Gyazz';
//  var do_auth = true;

var version = -1;
var name_id;
var title_id;

var editline = -1;
var eline = -1;

var data = [];
var dt = [];          // 背景色
var doi = [];
var zoomlevel = 0;
var spaces = [];      // 行に空白がいくつ含まれているか (桁揃えに利用)
var cache = {
    history : { } // #historyimageをなぞって表示するページ履歴 key:age, value:response
};

var posy = [];

var datestr = '';
var showold = false;

var sendTimeout;                     // 放置すると書き込み
var reloadTimeout = null;            // 放っておくとリロードするように
var reloadInterval = 10 * 60 * 1000; // 10分ごとにリロード

var editTimeout = null;

var searchmode = false;

var orig_md5; // getdata()したときのMD5

var KC = {
    tab:9, enter:13, ctrlD:17, left:37, up:38, right:39, down:40,
    k:75, n:78, p:80
};

var authbuf = [];

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
        [10*10*10*10*10*10*10*10*10*10*10,    40, 40, 40]
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
};

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
    if(editTimeout) clearTimeout(editTimeout);
    eline = -1;
    return true;
});

$(document).mousemove(function(event){
    if(editTimeout) clearTimeout(editTimeout);
    return true;
});

function longmousedown(){
    editline = eline;
    calcdoi();
    display(true);
}                 

$(document).mousedown(function(event){
    if(reloadTimeout) clearTimeout(reloadTimeout);
    reloadTimeout = setTimeout(reload,reloadInterval);
    
    y = event.pageY;
    if(y < 40){
        searchmode = true;
        return true;
    }
    searchmode = false;
    
    if(eline == -1){ // 行以外をクリック
	////writedata(true);
        editline = eline;
        calcdoi();
        display(true);
    }
    else {
        if(editTimeout) clearTimeout(editTimeout);
        editTimeout = setTimeout(longmousedown,300);
    }
    return true;
});

function indent(line){ // 先頭の空白文字の数
    if(typeof data[line] !== "string") return 0;
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
    var input = $("input#newtext");
    data[editline] = input.val();
});

var not_saved = false;

$(document).keydown(function(event){
    if(reloadTimeout) clearTimeout(reloadTimeout);
    reloadTimeout = setTimeout(reload,reloadInterval);
    
    var kc = event.which;
    var sk = event.shiftKey;
    var ck = event.ctrlKey;
    var cd = event.metaKey && !ck;
    var i;
    var m,m2;
    var dst;
    var tmp = [];
    
    if(searchmode) return true;
    
    not_saved = true;

    if(ck && kc == 0x53 && editline >= 0){
        transpose();
    }
    else if(kc == KC.enter){
        $('#query').val('');
	writedata();
    }
    else if(kc == KC.down && sk){ // Shift+↓ = 下にブロック移動
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
		writedata();
            }
        }
    }
    else if(kc == KC.k && ck){ // Ctrl+K カーソルより右側を削除する
        var input_tag = $("input#newtext");
        if(input_tag.val().match(/^\s*$/) && editline < data.length-1){ // 行が完全に削除された時
            data[editline] = ""; // 現在の行を削除
            deleteblankdata();
	    writedata();
            setTimeout(function(){
                // カーソルを行頭に移動
                input_tag = $("#newtext");
                input_tag[0].selectionStart = 0;
                input_tag[0].selectionEnd = 0;
            }, 10);
            return;
        }
        setTimeout(function(){ // Mac用。ctrl+kでカーソルより後ろを削除するまで待つ
            var cursor_pos = input_tag[0].selectionStart;
            if(input_tag.val().length > cursor_pos){ // ctrl+kでカーソルより後ろが削除されていない場合
                input_tag.val( input_tag.val().substring(0, cursor_pos) ); // カーソルより後ろを削除
                input_tag.selectionStart = cursor_pos;
                input_tag.selectionEnd = cursor_pos;
            }
        }, 10);
    }
    else if(kc == KC.down && ck && editline >= 0 && editline < data.length-1){ // Ctrl+↓ = 下の行と入れ替え
        var current_line_data = data[editline];
        data[editline] = data[editline+1];
        data[editline+1] = current_line_data;
        setTimeout(function(){
            editline += 1;
            deleteblankdata();
	    writedata();
        }, 1);
    }
    else if((kc == KC.down && !sk) || (kc == KC.n && !sk && ck)){ // ↓ = カーソル移動
        if(editline >= 0 && editline < data.length-1){
            var i;
            for(i=editline+1;i<data.length;i++){
                if(doi[i] >= -zoomlevel){
                    editline = i;
                    deleteblankdata();
		    writedata();
                    break;
                }
            }
        }
    }
    else if(kc == KC.up && sk){ // 上にブロック移動
        if(editline > 0){
            m = movelines(editline);
            dst = destline_up();
            if(dst >= 0){
                m2 = editline-dst;
                for(i=0;i<m2;i++) tmp[i] = data[dst+i];
                for(i=0;i<m;i++)  data[dst+i] = data[editline+i];
                for(i=0;i<m2;i++) data[dst+m+i] = tmp[i];
                editline = dst;
                deleteblankdata();
		writedata();
            }
        }
    }
    else if(kc == KC.up && ck && editline > 0){ // Ctrl+↑= 上の行と入れ替え
        var current_line_data = data[editline];
        data[editline] = data[editline-1];
        data[editline-1] = current_line_data;
        setTimeout(function(){
            editline -= 1;
            deleteblankdata();
	    writedata();
        }, 1);
    }
    else if((kc == KC.up && !sk) || (kc == KC.p && !sk && ck)){ // 上にカーソル移動
        if(editline > 0){
            var i;
            for(i=editline-1;i>=0;i--){
                if(doi[i] >= -zoomlevel){
                    editline = i;
                    deleteblankdata();
		    writedata();
                    break;
                }
            }
        }
    }
    if(kc == KC.tab && !sk || kc == KC.right && sk){ // indent
        if(editline >= 0 && editline < data.length){
            data[editline] = ' ' + data[editline];
	    writedata();
        }
    }
    if(kc == KC.tab && sk || kc == KC.left && sk){ // undent
        if(editline >= 0 && editline < data.length){
            var s = data[editline];
            if(s.substring(0,1) == ' '){
                data[editline] = s.substring(1,s.length);
            }
	    writedata();
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
        if(version >= 0){
            version -= 1;
            getdata();
        }
    }
    else if(kc >= 0x30 && kc <= 0x7e && editline < 0 && !cd && !ck){
        $('#querydiv').css('visibility','visible').css('display','block');
        $('#query').focus();
    }
    
    if(not_saved) $("input#newtext").css('background-color','#f0f0d0');
});

function deleteblankdata(){ // 空白行を削除
    for(i=0;i<data.length;i++){
        if(typeof data[i] === "string" && data[i].match(/^ *$/)){
            data.splice(i,1);
        }
    }
    calcdoi();
}

// 認証文字列をサーバに送る
function tell_auth(){
    var authstr = authbuf.sort().join(",");
    $.ajax({
        type: "POST",
        async: true,
        url: root + "/__tellauth",
        data: {
            name: name,
            title: title,
            authstr: authstr
        }
    });
}

// こうすると動的に関数を定義できる (クロージャ)
// 行をクリックしたとき呼ばれる
function linefunc(n){
    return function(event){
        if(writable){
            eline = n;
        }
        if(do_auth){
            authbuf.push(data[n]);
            tell_auth();
        }
        if(event.shiftKey){
            addblankline(n,indent(n));  // 上に行を追加
        }
    };
}

function setup(){ // 初期化
    name_id = MD5_hexhash(utf16to8(name));
    title_id = MD5_hexhash(utf16to8(title));
    for(var i=0;i<1000;i++){
        var y = $('<div>').attr('id','listbg'+i);
        var x = $('<span>').attr('id','list'+i).mousedown(linefunc(i));
        $('#contents').append(y.append(x));
    }
    reloadTimeout = setTimeout(reload,reloadInterval);
    
    $('#querydiv').css('display','none');
    
    b = $('body');
    b.bind("dragover", function(e) {
        return false;
    });
    b.bind("dragend", function(e) {
        return false;
    });
    b.bind("drop", function(e) {
        var files;
        e.preventDefault(); // デフォルトは「ファイルを開く」
        files = e.originalEvent.dataTransfer.files;
        sendfiles(files);
        return false;
    });
    
    $('#historyimage').hover(
        function(){
            showold = true;
        },
        function(){
            showold = false;
            getdata();
        }
    );
    
    $('#historyimage').mousemove(
        function(event){
            var imagewidth = parseInt($('#historyimage').attr('width'));
            var age = Math.floor((imagewidth + $('#historyimage').offset().left - event.pageX) * 25 / imagewidth);

            var show_history = function(res){
                datestr = res['date'];
                dt = res['age'];
                data = res['data'];
                // orig_md5 = MD5_hexhash(utf16to8(data.join("\n").replace(/\n+$/,'')+"\n"));
                search();
            };

            if(cache.history[age]){
                show_history(cache.history[age]);
                return;
            }
            $.ajax({
                type: "GET",
                async: false,
                url: root + "/" + name + "/" + title + "/json",
                data: {
                    age: age
                },
                success: function(res){
                    cache.history[age] = res;
                    show_history(res);
                }
            });
        }
    );

    $('#contents').mousedown(function(event){
	if(eline == -1){ // 行以外をクリック
	    writedata(true);
	}
    });

}

function display(delay){
    // zoomlevelに応じてバックグラウンドの色を変える
    var bgcolor = zoomlevel == 0 ? '#eeeeff' :
            zoomlevel == -1 ? '#e0e0c0' :
            zoomlevel == -2 ? '#c0c0a0' : '#a0a080';
    $("body").css('background-color',bgcolor);
    $('#datestr').text(version >= 0 || showold ? datestr : '');
    $('#title').attr('href',root + "/" + name + "/" + title + "/" + "__edit" + "/" + (version >= 0 ? version : 0));
    
    var i;
    if(delay){ // ちょっと待ってもう一度呼び出す!
        setTimeout("display()",200);
        return;
    }
    
    var input = $("input#newtext");
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
                input.css('position','absolute');
                input.css('visibility','visible');
                input.css('left',xmargin+25);
                input.css('top',p.position().top);
                input.blur();
                input.val(data[i]); // Firefoxの場合日本語入力中にこれが効かないことがあるような... blurしておけば大丈夫ぽい
                input.focus();
                input.mousedown(linefunc(i));
                setTimeout(function(){ $("input#newtext").focus(); }, 100); // 何故か少し待ってからfocus()を呼ばないとフォーカスされない...
            }
            else {
                var lastchar = '';
                if(i > 0 && typeof data[i-1] === "string") lastchar = data[i-1][data[i-1].length-1];
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
                    var m;
                    if(typeof data[i] === "string" &&
                       ( m = data[i].match(/\[\[(https:\/\/gist\.github\.com.*\?.*)\]\]/i) )){ // gistエンベッド
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
        $("#listbg"+i).css('background-color',(version >= 0 || showold) ? bgcol(dt[i]) : 'transparent');
        if(version >= 0){ // ツールチップに行の作成時刻を表示
            $("#list"+i).addClass('hover');
            date = new Date();
            createdate = new Date(date.getTime() - dt[i] * 1000);
            $("#list"+i).attr('title',createdate.toLocaleString());
            $(".hover").tipTip({
                maxWidth: "auto", //ツールチップ最大幅
                edgeOffset: 5, //要素からのオフセット距離
                activation: "hover", //hoverで表示、clickでも可能 
                defaultPosition: "bottom" //デフォルト表示位置
            });
        }
        else {
            $("#listbg"+i).removeClass('hover');
        }
    }
    
    for(i=data.length;i<1000;i++){
        $('#list'+i).css('display','none');
        $('#listbg'+i).css('display','none');
    }
    
    input.css('display',(editline == -1 ? 'none' : 'block'));
    
    for(i=0;i<data.length;i++){
        posy[i] = $('#list'+i).position().top;
        //posy[i] = $("#e" + i + "_0").offset().top;
    }
    aligncolumns();
    
    // リファラを消すプラグイン
    // http://logic.moo.jp/memo.php/archive/569
    // http://logic.moo.jp/data/filedir/569_3.js
    //
    //jQuery.kill_referrer.rewrite.init();
    follow_scroll();
}

function adjustIframeSize(newHeight,i) {
    var frame= document.getElementById("gistFrame"+i);
    frame.style.height = parseInt(newHeight) + "px";
}

function transpose(){ // 同じパタンが連続した行の行と桁を入れ換える
    if(editline < 0) return; // 編集中じゃない
    var i;
    var beginline = 0;
    var lastspaces = -1;
    var lastindent = -1;
    for(i=0;i<data.length;i++){
        if(spaces[i] > 0 && spaces[i] == lastspaces && indent(i) == lastindent){ // cont
        }
        else {
            if(lastspaces > 1 && i-beginline > 1){ // 同じパタンの連続を検出
                if(editline >= beginline && editline < i){
                    do_transpose(beginline,i-beginline,indent(beginline));
                    return;
                }
            }
            beginline = i;
        }
        lastspaces = spaces[i];
        lastindent = indent(i);
    }
    if(lastspaces > 1 && i-beginline > 1){ //  同じパタンの連続を検出
        if(editline >= beginline && editline < i){
            do_transpose(beginline,i-beginline,indent(beginline));
            return;
        }
    }
}

function do_transpose(beginline,lines,indent){  // begin番目からlines個の行の行と桁を入れ換え
    var x,y;
    var cols = spaces[beginline] + 1;
    var newlines = [];
    var indentstr = '';
    var i;
    for(i=0;i<indent;i++) indentstr += ' ';
    for(i=0;i<cols;i++){
        newlines[i] = indentstr;
    }
    
    for(y=0;y<lines;y++){
        var pre,post,inner;
        var m;
        var matched2 = [];
        var matched3 = [];
        var s = data[beginline+y];
        s = s.replace(/^\s*/,'');
        s = s.replace(/</g,'&lt;');
        while(m = s.match(/^(.*)\[\[\[(([^\]]|\][^\]]|[^\]]\])*)\]\]\](.*)$/)){ // [[[....]]]
            pre =   m[1];
            inner = m[2];
            post =  m[4];
            matched3.push(inner);
            s = pre + '<<3<' + (matched3.length-1) + '>3>>' + post;
        }
        while(m = s.match(/^(.*)\[\[(([^\]]|\][^\]]|[^\]]\])*)\]\](.*)$/)){ // [[....]]
            pre =   m[1];
            inner = m[2];
            post =  m[4];
            matched2.push(inner);
            s = pre + '<<2<' + (matched2.length-1) + '>2>>' + post;
        }
        var elements = s.split(/ /);
        for(i=0;i<elements.length;i++){
            var a;
            while(a = elements[i].match(/^(.*)<<3<(\d+)>3>>(.*)$/)){
                elements[i] = a[1] + "[[[" + matched3[a[2]] + "]]]" + a[3];
            }
            while(a = elements[i].match(/^(.*)<<2<(\d+)>2>>(.*)$/)){
                elements[i] = a[1] + "[[" + matched2[a[2]] + "]]" + a[3];
            }
        }
        for(i=0;i<elements.length;i++){
            if(y != 0) newlines[i] += " ";
            newlines[i] += elements[i];
        }
    }
    // data[] の beginlineからlines行をnewlines[]で置き換える
    data.splice(beginline,lines);
    for(i=0;i<newlines.length;i++){
        data.splice(beginline+i,0,newlines[i]);
    }
    
    writedata();
    editline = -1;
    display(true);
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
            //$(id).css('position','absolute').css('top',posy[line]);
            $(id).css('position','absolute').css('left',colpos);
            //$(id).css('position','absolute').css('line-height','').css('left',colpos).css('top',posy[line]);
            
            //$("#listbg"+line).css('line-height','');
        }
        colpos += maxwidth[i];
    }
}

function tag(s,line){
    // [[....]], [[[...]]]を[解析]
    if(typeof s !== "string") return;
    matched = [];
    s = s.replace(/</g,'&lt;');
    while(m = s.match(/^(.*)\[\[\[(([^\]]|\][^\]]|[^\]]\])*)\]\]\](.*)$/)){ // [[[....]]]
        pre =   m[1];
        inner = m[2];
        post =  m[4];
        if(t = inner.match(/^(https?:\/\/[^ ]+) (.*)\.(jpg|jpeg|jpe|png|gif)$/i)){ // [[[http:... ....jpg]]]
            matched.push('<a href="' + t[1] + '"><img src="' + t[2] + '.' + t[3] + '" border="none" target="_blank" height=80></a>');
        }
        else if(t = inner.match(/^(https?:\/\/.+)\.(jpg|jpeg|jpe|png|gif)$/i)){ // [[[http...jpg]]]
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
        else if(t = inner.match(/^(.+)\.(png|icon)$/i)){ // ページ名.icon or ページ名.pngでアイコン表示
            var link_to = null;
            var img_url = null;
            if(t[1].match(/^@[\da-z_]+$/i)){
                var screen_name = t[1].replace(/^@/,"");
                link_to = "http://twitter.com/"+screen_name;
                img_url = "http://twiticon.herokuapp.com/"+screen_name+"/mini";
            }
            else{
                link_to = root+"/"+name+"/"+t[1];
                img_url = link_to+"/icon";
            }
            matched.push('<a href="'+link_to+'" class="link" target="_blank"><img src="'+img_url+'" class="icon" height="24" border="0" alt="'+link_to+'" title="'+link_to+'" /></a>');
        }
        else if(t = inner.match(/^(.+)\.(png|icon|jpe?g|gif)[\*x×]([1-9][0-9]*)(|\.[0-9]+)$/i)){ // (URL|ページ名).(icon|png)x個数 でアイコンをたくさん表示
            var link_to = null;
            var img_url = null;
            if(t[1].match(/^@[\da-z_]+$/i)){
                var screen_name = t[1].replace(/^@/,"");
                link_to = "http://twitter.com/"+screen_name;
                img_url = "http://twiticon.herokuapp.com/"+screen_name+"/mini";
            }
            else if(t[1].match(/^https?:\/\/.+$/)){
                img_url = link_to = t[1]+"."+t[2];
            }
            else{
                link_to = root+"/"+name+"/"+t[1];
                img_url = link_to+"/icon";
            }
            var count = Number(t[3]);
            var icons = '<a href="'+link_to+'" class="link" target="_blank">';
            for(var i = 0; i < count; i++){
                icons += '<img src="'+img_url+'" class="icon" height="24" border="0" alt="'+t[1]+'" title="'+t[1]+'" />';
            }
            if(t[4].length > 0){
                var odd = Number("0"+t[4]);
                icons += '<img src="'+img_url+'" class="icon" height="24" width="'+24*odd+'" border="0" alt="'+link_to+'" title="'+link_to+'" />';
            }
            icons += '</a>';
            matched.push(icons);
        }
        else if(t = inner.match(/^((http[s]?|javascript):[^ ]+) (.*)$/)){ // [[http://example.com/ example]]
            target = t[1].replace(/"/g,'%22');
            matched.push('<a href="' + target + '" target="_blank">' + t[3] + '</a>');
        }
        else if(t = inner.match(/^((http[s]?|javascript):[^ ]+)$/)){ // [[http://example.com/]]
            target = t[1].replace(/"/g,'%22');
            matched.push('<a href="' + target + '" class="link" target="_blank">' + t[1] + '</a>');
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
        // googlemapの表示
        // [[E135.0W35.0]] や [[W35.0.0E135.0.0Z12]] のような記法で地図を表示
        else if(inner.match(/^([EW]\d+\.\d+[\d\.]*[NS]\d+\.\d+[\d\.]*|[NS]\d+\.\d+[\d\.]+[EW]\d+\.\d+[\d\.]*)(Z\d+)?$/)){
            var o = parseloc(inner);
            var s = "\
                <div id='map' style='width:300px;height:300px'></div>\
                <div id='line1' style='position:absolute;width:300px;height:4px;background-color:rgba(200,200,200,0.3);'></div>\
                <div id='line2' style='position:absolute;width:4px;height:300px;background-color:rgba(200,200,200,0.3);'></div>\
                <script type='text/javascript'>\
            var mapOptions = {\
            center: new google.maps.LatLng("+o.lat+","+o.lng+"),\
            zoom: "+o.zoom+",\
            mapTypeId: google.maps.MapTypeId.ROADMAP\
        };\
            var mapdiv = document.getElementById('map');\
            var map = new google.maps.Map(mapdiv,mapOptions);\
            var linediv1 = document.getElementById('line1');\
            var linediv2 = document.getElementById('line2');\
            google.maps.event.addListener(map, 'idle', function() {\
            linediv1.style.top = mapdiv.offsetTop+150-2;\
            linediv1.style.left = mapdiv.offsetLeft;\
            linediv2.style.top = mapdiv.offsetTop;\
            linediv2.style.left = mapdiv.offsetLeft+150-2;\
        });\
            google.maps.event.addListener(map, 'mouseup', function() {\
            var latlng = map.getCenter();\
            var o = {};\
            o.lng = latlng.lng();\
            o.lat = latlng.lat();\
            o.zoom = map.getZoom();\
            for(var i=0;i<data.length;i++){\
            data[i] = data[i].replace(/\\[\\[([EW]\\d+\\.\\d+[\\d\\.]*[NS]\\d+\\.\\d+[\\d\\.]*|[NS]\\d+\\.\\d+[\\d\\.]+[EW]\\d+\\.\\d+[\\d\\.]*)(Z\\d+)?\\]\\]/,'[['+locstr(o)+']]');\
        }\
            writedata();\
        });\
            </script>";
            matched.push(s);
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
        elements[i] = "<span id='e"+line+'_'+i+"'>" + elements[i] + "</span>"; // 各要素にidをつける jQuery風にすべき***
    }
    return elements.join(' ');
};

var olddatastr = '';
function writedata(force){
    not_saved = false;
    if(!writable) return;

    var datastr = data.join("\n").replace(/\n+$/,'')+"\n";
    if(!force && datastr == olddatastr){
	search();
	return;
    }
    olddatastr = datastr;

    cache.history = {}; // 履歴cacheをリセット

    $.ajax({
        type: "POST",
        async: true,
        url: root + "/__write",
        data: {
            name: name,
            title: title,
            orig_md5: orig_md5,
            data: datastr
        },
        beforeSend: function(xhr,settings){
            return true;
        },
        success: function(msg){
            $("input#newtext").css('background-color','#ddd');
            //$("#debug").text(msg);
            if(msg.match(/^conflict/)){
                // 再読み込み
                getdata(); // ここで強制書き換えしてしまうのがマズい? (2011/6/17)
            }
            else if(msg == 'protected'){
                // 再読み込み
                alert("このページは編集できません");
                getdata();
            }
            else if(msg == 'noconflict'){
                getdata(); // これをしないとorig_md5がセットされない
                // orig_md5 = MD5_hexhash(utf16to8(datastr)); でいいのか?
            }
            else {
                alert("Can't find old data - something's wrong.");
                getdata();
            }
        }
    });
}

function getdata(){ // 20050815123456.utf のようなテキストを読み出し
    $.ajax({
        type: "GET",
        async: false,
        url: root + "/" + name + "/" + title + "/json",
        data: {
            version: version >= 0 ? version : 0
        },
        success: function(res){
            datestr = res['date'];
            dt = res['age'];
            data = res['data'];
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
    version = -1;
    getdata();
    // display(); getdata()で呼ばれるはず
    if(reloadTimeout) clearTimeout(reloadTimeout);
    reloadTimeout = setTimeout(reload,reloadInterval);
}

function sendfiles(files){
    for (_i = 0, _len = files.length; _i < _len; _i++) {
        file = files[_i];
        sendfile(file, function(filename) {
            editline = data.length;
            if(filename.match(/\.(jpg|jpeg|png|gif)$/i)){
                data[editline] = '[[[' + root + "/upload/" + filename + ']]]';
            }
            else {
                data[editline] = '[[' + root + "/upload/" + filename + ' ' + file.name + ']]';
            }
            writedata();
            editline = -1;
            display(true);
        });
    }
}

function sendfile(file, callback){
    var fd;
    fd = new FormData;
    fd.append('uploadfile', file);
    $.ajax({
        url: root + "/__upload",
        type: "POST",
        data: fd,
        processData: false,
        contentType: false,
        dataType: 'text',
        error: function(XMLHttpRequest, textStatus, errorThrown) {
            // 通常はここでtextStatusやerrorThrownの値を見て処理を切り分けるか、
            // 単純に通信に失敗した際の処理を記述します。
            alert('upload fail');
            // alert(XMLHttpRequest);
            // alert(textStatus);
            // alert(errorThrown);
            this; // thisは他のコールバック関数同様にAJAX通信時のオプションを示します。
        },
        success: function(data) {
            //return callback.call(this);
            return callback(data);
        }
    });
    return false;
}

// 編集中の行が画面外に移動した時に、ブラウザをスクロールして追随する
function follow_scroll(){
    
    // 編集中かどうかチェック
    if(editline < 0) return;
    if(showold) return;
    
    var currentLinePos = $("input#newtext").offset().top;
    if( !(currentLinePos && currentLinePos > 0) ) return;
    var currentScrollPos = $("body").scrollTop();
    var windowHeight = window.innerHeight;
    
    // 編集中の行が画面内にある場合、スクロールする必要が無い
    if(currentScrollPos < currentLinePos &&
       currentLinePos < currentScrollPos+windowHeight) return;
    
    $("body").stop().animate({'scrollTop': currentLinePos - windowHeight/2}, 200);
};

