(function(){function e(e,t,i){t.is&&t.getCustomData("block_processed")||(t.is&&CKEDITOR.dom.element.setMarker(i,t,"block_processed",!0),e.push(t))}function t(t,i){function n(){this.foreach(function(e){/^(?!vbox|hbox)/.test(e.type)&&(e.setup||(e.setup=function(t){e.setValue(t.getAttribute(e.id)||"",1)}),!e.commit)&&(e.commit=function(t){var i=this.getValue();"dir"==e.id&&t.getComputedStyle("direction")==i||(i?t.setAttribute(e.id,i):t.removeAttribute(e.id))})})}var a=function(){var e=CKEDITOR.tools.extend({},CKEDITOR.dtd.$blockLimit);return t.config.div_wrapTable&&(delete e.td,delete e.th),e}(),o=CKEDITOR.dtd.div,r={},s=[];return{title:t.lang.div.title,minWidth:400,minHeight:165,contents:[{id:"info",label:t.lang.common.generalTab,title:t.lang.common.generalTab,elements:[{type:"hbox",widths:["50%","50%"],children:[{id:"elementStyle",type:"select",style:"width: 100%;",label:t.lang.div.styleSelectLabel,"default":"",items:[[t.lang.common.notSet,""]],onChange:function(){var e=["info:elementStyle","info:class","advanced:dir","advanced:style"],i=this.getDialog(),n=i._element&&i._element.clone()||new CKEDITOR.dom.element("div",t.document);this.commit(n,!0);for(var a,e=[].concat(e),o=e.length,r=0;o>r;r++)(a=i.getContentElement.apply(i,e[r].split(":")))&&a.setup&&a.setup(n,!0)},setup:function(e){for(var t in r)r[t].checkElementRemovable(e,!0)&&this.setValue(t,1)},commit:function(e){var t;(t=this.getValue())?r[t].applyToObject(e):e.removeAttribute("style")}},{id:"class",type:"text",label:t.lang.common.cssClass,"default":""}]}]},{id:"advanced",label:t.lang.common.advancedTab,title:t.lang.common.advancedTab,elements:[{type:"vbox",padding:1,children:[{type:"hbox",widths:["50%","50%"],children:[{type:"text",id:"id",label:t.lang.common.id,"default":""},{type:"text",id:"lang",label:t.lang.common.langCode,"default":""}]},{type:"hbox",children:[{type:"text",id:"style",style:"width: 100%;",label:t.lang.common.cssStyle,"default":"",commit:function(e){e.setAttribute("style",this.getValue())}}]},{type:"hbox",children:[{type:"text",id:"title",style:"width: 100%;",label:t.lang.common.advisoryTitle,"default":""}]},{type:"select",id:"dir",style:"width: 100%;",label:t.lang.common.langDir,"default":"",items:[[t.lang.common.notSet,""],[t.lang.common.langDirLtr,"ltr"],[t.lang.common.langDirRtl,"rtl"]]}]}]}],onLoad:function(){n.call(this);var e=this,i=this.getContentElement("info","elementStyle");t.getStylesSet(function(t){var n;if(t)for(var a=0;t.length>a;a++){var o=t[a];o.element&&"div"==o.element&&(n=o.name,r[n]=new CKEDITOR.style(o),i.items.push([n,n]),i.add(n,n))}i[i.items.length>1?"enable":"disable"](),setTimeout(function(){e._element&&i.setup(e._element)},0)})},onShow:function(){"editdiv"==i&&this.setupContent(this._element=CKEDITOR.plugins.div.getSurroundDiv(t))},onOk:function(){if("editdiv"==i)s=[this._element];else{var n,r,l,d=[],c={},u=[],p=t.getSelection(),m=p.getRanges(),h=p.createBookmarks();for(r=0;m.length>r;r++)for(l=m[r].createIterator();n=l.getNextParagraph();)if(n.getName()in a){var g=n.getChildren();for(n=0;g.count()>n;n++)e(u,g.getItem(n),c)}else{for(;!o[n.getName()]&&!n.equals(m[r].root);)n=n.getParent();e(u,n,c)}for(CKEDITOR.dom.element.clearAllMarkers(c),m=[],r=null,l=0;u.length>l;l++)n=u[l],g=t.elementPath(n).blockLimit,t.config.div_wrapTable&&g.is(["td","th"])&&(g=t.elementPath(g.getParent()).blockLimit),g.equals(r)||(r=g,m.push([])),m[m.length-1].push(n);for(r=0;m.length>r;r++){for(g=m[r][0],u=g.getParent(),n=1;m[r].length>n;n++)u=u.getCommonAncestor(m[r][n]);for(l=new CKEDITOR.dom.element("div",t.document),n=0;m[r].length>n;n++){for(g=m[r][n];!g.getParent().equals(u);)g=g.getParent();m[r][n]=g}for(n=0;m[r].length>n;n++)g=m[r][n],g.getCustomData&&g.getCustomData("block_processed")||(g.is&&CKEDITOR.dom.element.setMarker(c,g,"block_processed",!0),n||l.insertBefore(g),l.append(g));CKEDITOR.dom.element.clearAllMarkers(c),d.push(l)}p.selectBookmarks(h),s=d}for(d=s.length,c=0;d>c;c++)this.commitContent(s[c]),!s[c].getAttribute("style")&&s[c].removeAttribute("style");this.hide()},onHide:function(){"editdiv"==i&&this._element.removeCustomData("elementStyle"),delete this._element}}}CKEDITOR.dialog.add("creatediv",function(e){return t(e,"creatediv")}),CKEDITOR.dialog.add("editdiv",function(e){return t(e,"editdiv")})})();