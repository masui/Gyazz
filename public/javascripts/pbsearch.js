// pbsearch.js

function POBoxSearch(dic)
{
  this.dict = dic;
  this.search = pobox_search;
  this.regexp = pobox_regexp;
}

//POBoxSearch.search = function(pat,exact){

function pobox_search(p,exact)
{
  var pat = "^" + p;
  if(exact) pat = pat + "$";
  var re = new RegExp(pat);

  var cands = [];
  var ncands = 0;
  for(var i=0;i<this.dict.length && ncands < 60;i++){
    if(re.exec(this.dict[i][0]) != null){
      cands[ncands] = this.dict[i][1];
      ncands += 1;
    }
  }
  return cands;
}

function pobox_regexp(p,exact)
{
  var cands = this.search(p,exact);
  cands.push(p);
  var pat = "(" + cands.join("|") + ")";
  return new RegExp(pat,"i");
}

/*
dic = [
["hozon", "保存"],
["de", "で"],
["ha", "は"],
["tekisuto", "テキスト"],
["taitoru", "タイトル"],
["oku", "おく"],
["shite", "して"],
["youi", "用意"],
["wo", "を"],
["ni", "に"],
["mi", "み"],
["yomidashi", "読出し"],
["youna", "ような"],
["no", "の"]
]

pbs = new POBoxSearch(dic);
alert(pbs.search('t',false));

re = pbs.regexp('t',false)
alert(re.exec('タイトル'))
*/
