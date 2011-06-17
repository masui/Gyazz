//
// $Date: 2005-11-28 15:02:58 +0900 (Mon, 28 Nov 2005) $
//

var timeout;

//var TOP = "http://gyazz.com"
//var root = "http://Gyazz.com""

document.onkeyup = keyup;

function keyup(event){
    if(timeout) clearTimeout(timeout);
    timeout = setTimeout("writedata()",2000);
    $("#contents").css('background-color','#f0f0d0');
}

function writedata(){
    datastr = $('#contents').val();
    postdata = "data=" + encodeURIComponent(name + "\n" + title + "\n" + orig_md5 + "\n" + datastr)
	$.ajax({
		type: "POST",
		sync: true,
		url: root + "/__write",
		data: postdata,
		success: function(msg){
		    $("#contents").css('background-color','#ffffff');
		    if(msg.match(/^conflict/)){
			// 再読み込み
			//alert(msg);
			getdata(); // ここで強制書き換えしてしまうのがマズい (2011/6/17)
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
		orig_md5 = MD5_hexhash(utf16to8(data.join("\n")+"\n"));
		search();
	    }
	});
}
