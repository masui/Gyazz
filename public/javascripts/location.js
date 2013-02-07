//
function frac(v){
    return v - Math.floor(v);
}

function val2loc(v){ // 35.5 => 35.30.0.0
    var negative = false;
    if(v < 0){
	negative = true;
	v = -v;
    }
    var deg = Math.floor(v);
    v = frac(v) * 60.0;
    var min = Math.floor(v);
    v = frac(v) * 60.0;
    var sec = Math.floor(v);
    v = frac(v) * 100.0;
    var sec2 = Math.floor(v);
    return (negative ? '-' : '') + deg + '.' + min + '.' + sec + '.' + sec2;
}

function loc2val(loc){ // '35.30.00.00' ⇒ 35.5
    var negative = loc.match(/^\-/);
    var a = loc.split(/\./);
    var v = parseInt(a[0]) + parseInt(a[1])/60.0 +
	parseInt(a[2])/60.0/60.0 + parseInt(a[3])/60.0/60.0/100.0;
    return (negative? -v : v);
}

function parseloc(s){ // 'E130.43.19.70N31.47.47.34Z2' => {130.7221, 31.79648, 2}
    var a;
    var o = {}
    o.zoom = 1;
    o.lat = 0.0;
    o.lng = 0.0;
    while(a = s.match(/^([EWNSZ])([0-9\.]+)(.*)$/)){
	var v;
	if(a[2].match(/\..*\./)){
	    v = loc2val(a[2]);
	}
	else {
	    v = parseFloat(a[2]);
	}
	switch(a[1]){
	case 'E': o['lng'] = v; break;
	case 'W': o['lng'] = -v; break;
	case 'N': o['lat'] = v; break;
	case 'S': o['lat'] = -v; break;
	case 'Z': o['zoom'] = v; break;
	}
	s = a[3];
    }
    return o;
}

function locstr(o){ // {130.7221, 31.79648, 2} => 'E130.43.19.70N31.47.47.34Z2'
    ew = (o.lng > 0 ? 'E'+val2loc(o.lng) : 'W'+val2loc(-o.lng));
    ns = (o.lat > 0 ? 'N'+val2loc(o.lat) : 'S'+val2loc(-o.lat));
    return ew + ns + 'Z' + o.zoom;
}

//s = 'E130.43.19.70N31.47.47.34Z10';
//print(s);
//obj = parseloc(s);
//print(obj.lng);
//print(obj.lat);
//print(obj.zoom);
//print(locstr(obj));


// v = 35.12345;
// s = val2loc(v);
// print(s);
// v = loc2val(s);
// print(v);





