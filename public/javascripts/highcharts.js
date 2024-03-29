/*!
 * 
 *
 *
 * @license Highcharts JS v2.0.5 (FusionCharts optimized)
 *
 * (c) 2009-2010 Torstein Hønsi
 * Embedded license information at <http://www.fusioncharts.com/license>
 * All modifications made to this code are copyright of FusionCharts Technologies LLP.
 * License: www.highcharts.com/license
 *
 *
 * (c) 2009-2010 Torstein Hønsi
 * Embedded license information at <http://www.fusioncharts.com/license>
 * All modifications made to this code are copyright of FusionCharts Technologies LLP.
 * License: www.highcharts.com/license
 */
(function(){
    var u=document,win=window,math=Math,mathRound=math.round,mathFloor=math.floor,mathCeil=math.ceil,mathMax=math.max,mathMin=math.min,mathAbs=math.abs,mathCos=math.cos,mathSin=math.sin,userAgent=navigator.userAgent,isIE=/msie/i.test(userAgent)&&!win.opera,isWebKit=/AppleWebKit/.test(userAgent),hasSVG=win.SVGAngle||u.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#BasicStructure","1.1"),colorCounter,symbolCounter,symbolSizes={},idCounter=0,timeFactor=1,garbageBin,defaultOptions,dateFormat,UNDEFINED,DIV='div',ABSOLUTE='absolute',RELATIVE='relative',HIDDEN='hidden',PREFIX='highcharts-',VISIBLE='visible',PX='px',NONE='none',M='M',L='L',TRACKER_FILL='rgba(192,192,192,'+(hasSVG?0.000001:0.002)+')',NORMAL_STATE='',HOVER_STATE='hover',SELECT_STATE='select',makeTime,getMinutes,getHours,getDay,getDate,getMonth,getFullYear,setMinutes,setHours,setDate,setMonth,setFullYear,globalAdapter=win.HighchartsAdapter,adapter=globalAdapter||{},each=adapter.each,grep=adapter.grep,map=adapter.map,merge=adapter.merge,hyphenate=adapter.hyphenate,addEvent=adapter.addEvent,removeEvent=adapter.removeEvent,fireEvent=adapter.fireEvent,animate=adapter.animate,stop=adapter.stop,getAjax=adapter.getAjax,seriesTypes={};

    function extend(a,b){
        if(!a){
            a={}
        }
        for(var n in b){
        a[n]=b[n]
        }
        return a
    }
    function defined(a){
    return a!==UNDEFINED&&a!==null
    }
    function attr(a,b,c){
    var d,setAttribute='setAttribute',ret;
    if(typeof b=='string'){
        if(defined(c)){
            a[setAttribute](b,c)
            }else if(a&&a.getAttribute){
            ret=a.getAttribute(b)
            }
        }else if(defined(b)&&typeof b=='object'){
    for(d in b){
        a[setAttribute](d,b[d])
        }
    }
    return ret
}
function splat(a){
    if(!a||a.constructor!=Array){
        a=[a]
        }
        return a
    }
    function pick(){
    var a=arguments,i,arg;
    for(i=0;i<a.length;i++){
        arg=a[i];
        if(defined(arg)){
            return arg
            }
        }
    }
function serializeCSS(a){
    var s='',key;
    for(key in a){
        s+=hyphenate(key)+':'+a[key]+';'
        }
        return s
    }
    function css(a,b){
    if(isIE){
        if(b&&b.opacity!==UNDEFINED){
            b.filter='alpha(opacity='+(b.opacity*100)+')'
            }
        }
    extend(a.style,b)
}
function createElement(a,b,c,d,e){
    var f=u.createElement(a);
    if(b){
        extend(f,b)
        }
        if(e){
        css(f,{
            padding:0,
            border:NONE,
            margin:0
        })
        }
        if(c){
        css(f,c)
        }
        if(d){
        d.appendChild(f)
        }
        return f
    }
    if(!globalAdapter&&win.jQuery){
    var v=jQuery;
    each=function(a,b){
        for(var i=0,len=a.length;i<len;i++){
            if(b.call(a[i],a[i],i,a)===false){
                return i
                }
            }
        };

grep=v.grep;
map=function(a,b){
    var c=[];
    for(var i=0,len=a.length;i<len;i++){
        c[i]=b.call(a[i],a[i],i,a)
        }
        return c
    };

merge=function(){
    var a=arguments;
    return v.extend(true,null,a[0],a[1],a[2],a[3])
    };

hyphenate=function(c){
    return c.replace(/([A-Z])/g,function(a,b){
        return'-'+b.toLowerCase()
        })
    };

addEvent=function(a,b,c){
    v(a).bind(b,c)
    };

removeEvent=function(a,b,c){
    var d=u.removeEventListener?'removeEventListener':'detachEvent';
    if(u[d]&&!a[d]){
        a[d]=function(){}
    }
    v(a).unbind(b,c)
};

fireEvent=function(a,b,c,d){
    var e=v.Event(b),detachedType='detached'+b;
    extend(e,c);
    if(a[b]){
        a[detachedType]=a[b];
        a[b]=null
        }
        v(a).trigger(e);
    if(a[detachedType]){
        a[b]=a[detachedType];
        a[detachedType]=null
        }
        if(d&&!e.isDefaultPrevented()){
        d(e)
        }
    };

animate=function(a,b,c){
    var d=v(a);
    d.stop();
    d.animate(b,c)
    };

stop=function(a){
    v(a).stop()
    };

getAjax=function(a,b){
    v.get(a,null,b)
    };

v.extend(v.easing,{
    easeOutQuad:function(x,t,b,c,d){
        return-c*(t/=d)*(t-2)+b
        }
    });
var w=jQuery.fx.step._default,oldCur=jQuery.fx.prototype.cur;
v.fx.step._default=function(a){
    var b=a.elem;
    if(b.attr){
        b.attr(a.prop,a.now)
        }else{
        w.apply(this,arguments)
        }
    };

v.fx.prototype.cur=function(){
    var a=this.elem,r;
    if(a.attr){
        r=a.attr(this.prop)
        }else{
        r=oldCur.apply(this,arguments)
        }
        return r
    }
}else if(!globalAdapter&&win.MooTools){
    each=$each;
    map=function(a,b){
        return a.map(b)
        };

    grep=function(a,b){
        return a.filter(b)
        };

    merge=$merge;
    hyphenate=function(a){
        return a.hyphenate()
        };

    addEvent=function(a,b,c){
        if(typeof b=='string'){
            if(b=='unload'){
                b='beforeunload'
                }
                if(!a.addEvent){
                if(a.nodeName){
                    a=$(a)
                    }else{
                    extend(a,new Events())
                    }
                }
            a.addEvent(b,c)
        }
    };

removeEvent=function(a,b,c){
    if(b){
        if(b=='unload'){
            b='beforeunload'
            }
            a.removeEvent(b,c)
        }
    };

fireEvent=function(a,b,c,d){
    b=new Event({
        type:b,
        target:a
    });
    b=extend(b,c);
    b.preventDefault=function(){
        d=null
        };

    if(a.fireEvent){
        a.fireEvent(b.type,b)
        }
        if(d){
        d(b)
        }
    };

animate=function(a,b,c){
    var d=a.attr,effect;
    if(d&&!a.setStyle){
        a.setStyle=a.getStyle=a.attr;
        a.$family=a.uid=true
        }
        stop(a);
    effect=new Fx.Morph(d?a:$(a),extend(c,{
        transition:Fx.Transitions.Quad.easeInOut
        }));
    effect.start(b);
    a.fx=effect
    };

stop=function(a){
    if(a.fx){
        a.fx.cancel()
        }
    };

getAjax=function(a,b){
    (new Request({
        url:a,
        method:'get',
        onSuccess:b
    })).send()
    }
}
function setTimeMethods(){
    var g=defaultOptions.global.useUTC;
    makeTime=g?Date.UTC:function(a,b,c,d,e,f){
        return new Date(a,b,pick(c,1),pick(d,0),pick(e,0),pick(f,0)).getTime()
        };

    getMinutes=g?'getUTCMinutes':'getMinutes';
    getHours=g?'getUTCHours':'getHours';
    getDay=g?'getUTCDay':'getDay';
    getDate=g?'getUTCDate':'getDate';
    getMonth=g?'getUTCMonth':'getMonth';
    getFullYear=g?'getUTCFullYear':'getFullYear';
    setMinutes=g?'setUTCMinutes':'setMinutes';
    setHours=g?'setUTCHours':'setHours';
    setDate=g?'setUTCDate':'setDate';
    setMonth=g?'setUTCMonth':'setMonth';
    setFullYear=g?'setUTCFullYear':'setFullYear'
    }
    function setOptions(a){
    defaultOptions=merge(defaultOptions,a);
    setTimeMethods();
    return defaultOptions
    }
    function getOptions(){
    return defaultOptions
    }
    function discardElement(a){
    if(!garbageBin){
        garbageBin=createElement(DIV)
        }
        if(a){
        garbageBin.appendChild(a)
        }
        garbageBin.innerHTML=''
    }
    var z={
    enabled:true,
    align:'center',
    x:0,
    y:15,
    style:{
        color:'#666',
        fontSize:'11px'
    }
};

defaultOptions={
    colors:['#4572A7','#AA4643','#89A54E','#80699B','#3D96AE','#DB843D','#92A8CD','#A47D7C','#B5CA92'],
    symbols:['circle','diamond','square','triangle','triangle-down'],
    lang:{
        loading:'Loading...',
        months:['January','February','March','April','May','June','July','August','September','October','November','December'],
        weekdays:['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'],
        decimalPoint:'.',
        resetZoom:'Reset zoom',
        resetZoomTitle:'Reset zoom level 1:1',
        thousandsSep:','
    },
    global:{
        useUTC:true
    },
    chart:{
        margin:[50,50,90,80],
        borderColor:'#4572A7',
        borderRadius:5,
        defaultSeriesType:'line',
        ignoreHiddenSeries:true,
        style:{
            fontFamily:'"Lucida Grande", "Lucida Sans Unicode", Verdana, Arial, Helvetica, sans-serif',
            fontSize:'12px'
        },
        backgroundColor:'#FFFFFF',
        plotBorderColor:'#C0C0C0'
    },
    title:{
        text:'Chart title',
        x:0,
        y:20,
        align:'center',
        style:{
            color:'#3E576F',
            fontSize:'16px'
        }
    },
subtitle:{
    text:'',
    x:0,
    y:40,
    align:'center',
    style:{
        color:'#6D869F'
    }
},
plotOptions:{
    line:{
        allowPointSelect:false,
        showCheckbox:false,
        animation:true,
        events:{},
        lineWidth:2,
        shadow:true,
        marker:{
            enabled:true,
            lineWidth:0,
            radius:4,
            lineColor:'#FFFFFF',
            states:{
                hover:{},
                select:{
                    fillColor:'#FFFFFF',
                    lineColor:'#000000',
                    lineWidth:2
                }
            }
        },
point:{
    events:{}
},
dataLabels:merge(z,{
    enabled:false,
    y:-6,
    formatter:function(){
        return this.y
        }
    }),
showInLegend:true,
states:{
    hover:{
        lineWidth:3,
        marker:{}
},
select:{
    marker:{}
}
},
stickyTracking:true
}
},
labels:{
    style:{
        position:ABSOLUTE,
        color:'#3E576F'
    }
},
legend:{
    enabled:true,
    align:'center',
    layout:'horizontal',
    labelFormatter:function(){
        return this.name
        },
    borderWidth:1,
    borderColor:'#909090',
    borderRadius:5,
    shadow:false,
    style:{
        padding:'5px'
    },
    itemStyle:{
        cursor:'pointer',
        color:'#3E576F'
    },
    itemHoverStyle:{
        cursor:'pointer',
        color:'#000000'
    },
    itemHiddenStyle:{
        color:'#C0C0C0'
    },
    itemCheckboxStyle:{
        position:ABSOLUTE,
        width:'13px',
        height:'13px'
    },
    symbolWidth:16,
    symbolPadding:5,
    verticalAlign:'bottom',
    x:15,
    y:-15
},
loading:{
    hideDuration:100,
    labelStyle:{
        fontWeight:'bold',
        position:RELATIVE,
        top:'1em'
    },
    showDuration:100,
    style:{
        position:ABSOLUTE,
        backgroundColor:'white',
        opacity:0.5,
        textAlign:'center'
    }
},
tooltip:{
    enabled:true,
    formatter:function(){
        var a=this,series=a.series,xAxis=series.xAxis,x=a.x;
        return'<b>'+(a.point.name||series.name)+'</b><br/>'+(defined(x)?'X value: '+(xAxis&&xAxis.options.type=='datetime'?dateFormat(null,x):x)+'<br/>':'')+'Y value: '+a.y
        },
    backgroundColor:'rgba(255, 255, 255, .85)',
    borderWidth:2,
    borderRadius:5,
    shadow:true,
    snap:10,
    style:{
        color:'#333333',
        fontSize:'12px',
        padding:'5px',
        whiteSpace:'nowrap'
    }
},
toolbar:{
    itemStyle:{
        color:'#4572A7',
        cursor:'pointer'
    }
},
credits:{
    enabled:true,
    text:'Highcharts.com',
    href:'http://www.highcharts.com',
    style:{
        cursor:'pointer',
        color:'#909090',
        fontSize:'10px'
    }
}
};

var A={
    dateTimeLabelFormats:{
        second:'%H:%M:%S',
        minute:'%H:%M',
        hour:'%H:%M',
        day:'%e. %b',
        week:'%e. %b',
        month:'%b \'%y',
        year:'%Y'
    },
    endOnTick:false,
    gridLineColor:'#C0C0C0',
    labels:z,
    lineColor:'#C0D0E0',
    lineWidth:1,
    max:null,
    min:null,
    minPadding:0.01,
    maxPadding:0.01,
    maxZoom:null,
    minorGridLineColor:'#E0E0E0',
    minorGridLineWidth:1,
    minorTickColor:'#A0A0A0',
    minorTickLength:2,
    minorTickPosition:'outside',
    minorTickWidth:1,
    showFirstLabel:true,
    showLastLabel:false,
    startOfWeek:1,
    startOnTick:false,
    tickColor:'#C0D0E0',
    tickLength:5,
    tickmarkPlacement:'between',
    tickPixelInterval:100,
    tickPosition:'outside',
    tickWidth:1,
    title:{
        align:'middle',
        margin:35,
        style:{
            color:'#6D869F',
            fontWeight:'bold'
        }
    },
type:'linear'
},defaultYAxisOptions=merge(A,{
    endOnTick:true,
    gridLineWidth:1,
    tickPixelInterval:72,
    showLastLabel:true,
    labels:{
        align:'right',
        x:-8,
        y:3
    },
    lineWidth:0,
    maxPadding:0.05,
    minPadding:0.05,
    startOnTick:true,
    tickWidth:0,
    title:{
        margin:40,
        rotation:270,
        text:'Y-values'
    }
}),defaultLeftAxisOptions={
    labels:{
        align:'right',
        x:-8,
        y:3
    },
    title:{
        rotation:270
    }
},defaultRightAxisOptions={
    labels:{
        align:'left',
        x:8,
        y:3
    },
    title:{
        rotation:90
    }
},defaultBottomAxisOptions={
    labels:{
        align:'center',
        x:0,
        y:14
    },
    title:{
        rotation:0
    }
},defaultTopAxisOptions=merge(defaultBottomAxisOptions,{
    labels:{
        y:-5
    }
});
var B=defaultOptions.plotOptions,defaultSeriesOptions=B.line;
B.spline=merge(defaultSeriesOptions);
B.scatter=merge(defaultSeriesOptions,{
    lineWidth:0,
    states:{
        hover:{
            lineWidth:0
        }
    }
});
B.area=merge(defaultSeriesOptions,{});
B.areaspline=merge(B.area);
B.column=merge(defaultSeriesOptions,{
    borderColor:'#FFFFFF',
    borderWidth:1,
    borderRadius:0,
    groupPadding:0.2,
    marker:null,
    pointPadding:0.1,
    minPointLength:0,
    states:{
        hover:{
            brightness:0.1,
            shadow:false
        },
        select:{
            color:'#C0C0C0',
            borderColor:'#000000',
            shadow:false
        }
    }
});
B.bar=merge(B.column,{
    dataLabels:{
        align:'left',
        x:5,
        y:0
    }
});
B.pie=merge(defaultSeriesOptions,{
    borderColor:'#FFFFFF',
    borderWidth:1,
    center:['50%','50%'],
    colorByPoint:true,
    legendType:'point',
    marker:null,
    size:'90%',
    slicedOffset:10,
    states:{
        hover:{
            brightness:0.1,
            shadow:false
        }
    }
});
setTimeMethods();
function extendClass(a,b){
    var c=function(){};

    c.prototype=new a();
    extend(c.prototype,b);
    return c
    }
    var C=function(c){
    var d=[],result;
    function init(a){
        if((result=/rgba\(\s*([0-9]{1,3})\s*,\s*([0-9]{1,3})\s*,\s*([0-9]{1,3})\s*,\s*([0-9]?(?:\.[0-9]+)?)\s*\)/.exec(a))){
            d=[parseInt(result[1],10),parseInt(result[2],10),parseInt(result[3],10),parseFloat(result[4],10)]
            }else if((result=/#([a-fA-F0-9]{2})([a-fA-F0-9]{2})([a-fA-F0-9]{2})/.exec(a))){
            d=[parseInt(result[1],16),parseInt(result[2],16),parseInt(result[3],16),1]
            }
        }
    function get(a){
    var b;
    if(d&&!isNaN(d[0])){
        if(a=='rgb'){
            b='rgb('+d[0]+','+d[1]+','+d[2]+')'
            }else if(a=='a'){
            b=d[3]
            }else{
            b='rgba('+d.join(',')+')'
            }
        }else{
    b=c
    }
    return b
}
function brighten(a){
    if(typeof a=='number'&&a!==0){
        for(var i=0;i<3;i++){
            d[i]+=parseInt(a*255,10);
            if(d[i]<0){
                d[i]=0
                }
                if(d[i]>255){
                d[i]=255
                }
            }
        }
    return this
}
function setOpacity(a){
    d[3]=a;
    return this
    }
    init(c);
return{
    get:get,
    brighten:brighten,
    setOpacity:setOpacity
}
};

function numberFormat(a,b,e,f){
    var g=defaultOptions.lang,n=a,c=isNaN(b=mathAbs(b))?2:b,d=e===undefined?g.decimalPoint:e,t=f===undefined?g.thousandsSep:f,s=n<0?"-":"",i=parseInt(n=mathAbs(+n||0).toFixed(c),10)+"",j=(j=i.length)>3?j%3:0;
    return s+(j?i.substr(0,j)+t:"")+i.substr(j).replace(/(\d{3})(?=\d)/g,"$1"+t)+(c?d+mathAbs(n-i).toFixed(c).slice(2):"")
    }
    dateFormat=function(b,c,d){
    function pad(a){
        return a.toString().replace(/^([0-9])$/,'0$1')
        }
        if(!defined(c)||isNaN(c)){
        return'Invalid date'
        }
        b=pick(b,'%Y-%m-%d %H:%M:%S');
    var e=new Date(c*timeFactor),hours=e[getHours](),day=e[getDay](),dayOfMonth=e[getDate](),month=e[getMonth](),fullYear=e[getFullYear](),lang=defaultOptions.lang,langWeekdays=lang.weekdays,langMonths=lang.months,replacements={
        'a':langWeekdays[day].substr(0,3),
        'A':langWeekdays[day],
        'd':pad(dayOfMonth),
        'e':dayOfMonth,
        'b':langMonths[month].substr(0,3),
        'B':langMonths[month],
        'm':pad(month+1),
        'y':fullYear.toString().substr(2,2),
        'Y':fullYear,
        'H':pad(hours),
        'I':pad((hours%12)||12),
        'l':(hours%12)||12,
        'M':pad(e[getMinutes]()),
        'p':hours<12?'AM':'PM',
        'P':hours<12?'am':'pm',
        'S':pad(e.getSeconds())
        };

    for(var f in replacements){
        b=b.replace('%'+f,replacements[f])
        }
        return d?b.substr(0,1).toUpperCase()+b.substr(1):b
    };

function getPosition(a){
    var p={
        x:a.offsetLeft,
        y:a.offsetTop
        };
    while(a.offsetParent){
        a=a.offsetParent;
        p.x+=a.offsetLeft;
        p.y+=a.offsetTop;
        if(a!=u.body&&a!=u.documentElement){
            p.x-=a.scrollLeft;
            p.y-=a.scrollTop
            }
        }
    return p
}
function SVGElement(){}
SVGElement.prototype={
    init:function(a,b){
        this.element=u.createElementNS('http://www.w3.org/2000/svg',b);
        this.renderer=a
        },
    animate:function(a,b){
        animate(this,a,b)
        },
    attr:function(a,b){
        var c,value,i,child,element=this.element,nodeName=element.nodeName,renderer=this.renderer,skipAttr,shadows=this.shadows,hasSetSymbolSize,ret=this;
        if(typeof a=='string'&&defined(b)){
            c=a;
            a={};

            a[c]=b
            }
            if(typeof a=='string'){
            c=a;
            if(nodeName=='circle'){
                c={
                    x:'cx',
                    y:'cy'
                }
                [c]||c
                }else if(c=='strokeWidth'){
                c='stroke-width'
                }
                ret=parseFloat(attr(element,c)||this[c]||0)
            }else{
            for(c in a){
                value=a[c];
                if(c=='d'){
                    if(value&&value.join){
                        value=value.join(' ')
                        }
                        if(/(NaN|  |^$)/.test(value)){
                        value='M 0 0'
                        }
                    }else if(c=='x'&&nodeName=='text'){
                for(i=0;i<element.childNodes.length;i++){
                    child=element.childNodes[i];
                    if(attr(child,'x')==attr(element,'x')){
                        attr(child,'x',value)
                        }
                    }
                }else if(c=='fill'){
                value=renderer.color(value,element,c)
                }else if(nodeName=='circle'){
                c={
                    x:'cx',
                    y:'cy'
                }
                [c]||c
                }else if(c=='translateX'||c=='translateY'){
                this[c]=value;
                this.updateTransform();
                skipAttr=true
                }else if(c=='stroke'){
                value=renderer.color(value,element,c)
                }else if(c=='isTracker'){
                this[c]=value
                }
                if(c=='strokeWidth'){
                c='stroke-width'
                }
                if(isWebKit&&c=='stroke-width'&&value===0){
                value=0.000001
                }
                if(this.symbolName&&/^(x|y|r|start|end|innerR)/.test(c)){
                if(!hasSetSymbolSize){
                    this.symbolAttr(a);
                    hasSetSymbolSize=true
                    }
                    skipAttr=true
                }
                if(shadows&&/^(width|height|visibility|x|y|d)$/.test(c)){
                i=shadows.length;
                while(i--){
                    attr(shadows[i],c,value)
                    }
                }
            if(c=='text'){
            renderer.buildText(element,value)
            }else if(!skipAttr){
            attr(element,c,value)
            }
        }
}
return ret
},
symbolAttr:function(a){
    var b=this;
    b.x=pick(a.x,b.x);
    b.y=parseFloat(pick(a.y,b.y));
    b.r=pick(a.r,b.r);
    b.start=pick(a.start,b.start);
    b.end=pick(a.end,b.end);
    b.width=pick(a.width,b.width);
    b.height=parseFloat(pick(a.height,b.height));
    b.innerR=pick(a.innerR,b.innerR);
    b.attr({
        d:b.renderer.symbols[b.symbolName](b.x,b.y,b.r,{
            start:b.start,
            end:b.end,
            width:b.width,
            height:b.height,
            innerR:b.innerR
            })
        })
    },
clip:function(a){
    return this.attr('clip-path','url('+this.renderer.url+'#'+a.id+')')
    },
css:function(a){
    var b=this;
    if(a&&a.color){
        a.fill=a.color
        }
        a=extend(b.styles,a);
    b.attr({
        style:serializeCSS(a)
        });
    b.styles=a;
    return b
    },
on:function(a,b){
    this.element['on'+a]=b;
    return this
    },
translate:function(x,y){
    var a=this;
    a.translateX=x;
    a.translateY=y;
    a.updateTransform();
    return a
    },
invert:function(){
    var a=this;
    a.inverted=true;
    a.updateTransform();
    return a
    },
updateTransform:function(){
    var a=this,translateX=a.translateX||0,translateY=a.translateY||0,inverted=a.inverted,transform=[];
    if(inverted){
        translateX+=a.attr('width');
        translateY+=a.attr('height')
        }
        if(translateX||translateY){
        transform.push('translate('+translateX+','+translateY+')')
        }
        if(inverted){
        transform.push('rotate(90) scale(-1,1)')
        }
        if(transform.length){
        attr(a.element,'transform',transform.join(' '))
        }
    },
toFront:function(){
    var a=this.element;
    a.parentNode.appendChild(a);
    return this
    },
getBBox:function(){
    return this.element.getBBox()
    },
show:function(){
    return this.attr({
        visibility:VISIBLE
    })
    },
hide:function(){
    return this.attr({
        visibility:HIDDEN
    })
    },
add:function(a){
    var b=this.renderer,parentWrapper=a||b,parentNode=parentWrapper.element||b.box,childNodes=parentNode.childNodes,element=this.element,zIndex=attr(element,'zIndex'),otherElement,otherZIndex,i;
    this.parentInverted=a&&a.inverted;
    if(zIndex){
        parentWrapper.handleZ=true;
        zIndex=parseInt(zIndex,10)
        }
        if(parentWrapper.handleZ){
        for(i=0;i<childNodes.length;i++){
            otherElement=childNodes[i];
            otherZIndex=attr(otherElement,'zIndex');
            if(otherElement!=element&&(parseInt(otherZIndex,10)>zIndex||(!defined(zIndex)&&defined(otherZIndex)))){
                parentNode.insertBefore(element,otherElement);
                return this
                }
            }
        }
    parentNode.appendChild(element);
return this
},
destroy:function(){
    var b=this,element=b.element,shadows=b.shadows,parentNode=element.parentNode,key;
    element.onclick=element.onmouseout=element.onmouseover=element.onmousemove=null;
    stop(b);
    if(parentNode){
        parentNode.removeChild(element)
        }
        if(shadows){
        each(shadows,function(a){
            parentNode=a.parentNode;
            if(parentNode){
                parentNode.removeChild(a)
                }
            })
    }
    for(key in b){
    delete b[key]
}
return null
},
empty:function(){
    var a=this.element,childNodes=a.childNodes,i=childNodes.length;
    while(i--){
        a.removeChild(childNodes[i])
        }
    },
shadow:function(a){
    var b=[],i,shadow,element=this.element,transform=this.parentInverted?'(-1,-1)':'(1,1)';
    if(a){
        for(i=1;i<=3;i++){
            shadow=element.cloneNode(0);
            attr(shadow,{
                'isShadow':'true',
                'stroke':'rgb(0, 0, 0)',
                'stroke-opacity':0.05*i,
                'stroke-width':7-2*i,
                'transform':'translate'+transform,
                'fill':NONE
            });
            element.parentNode.insertBefore(shadow,element);
            b.push(shadow)
            }
            this.shadows=b
        }
        return this
    }
};

var D=function(){
    this.init.apply(this,arguments)
    };

D.prototype={
    init:function(a,b,c){
        var d=u.createElementNS('http://www.w3.org/2000/svg','svg'),loc=location;
        attr(d,{
            width:b,
            height:c,
            xmlns:'http://www.w3.org/2000/svg',
            version:'1.1'
        });
        a.appendChild(d);
        this.Element=SVGElement;
        this.box=d;
        this.url=isIE?'':loc.href.replace(/#.*?$/,'');
        this.defs=this.createElement('defs').add()
        },
    createElement:function(a){
        var b=new this.Element();
        b.init(this,a);
        return b
        },
    buildText:function(f,g){
        var h=g.toString().replace(/<(b|strong)>/g,'<span style="font-weight:bold">').replace(/<(i|em)>/g,'<span style="font-style:italic">').replace(/<a/g,'<span').replace(/<\/(b|strong|i|em|a)>/g,'</span>').split(/<br[^>]?>/g),childNodes=f.childNodes,styleRegex=/style="([^"]+)"/,hrefRegex=/href="([^"]+)"/,parentX=attr(f,'x'),i=childNodes.length;
        while(i--){
            f.removeChild(childNodes[i])
            }
            each(h,function(c,d){
            var e,spanNo=0;
            c=c.replace(/<span/g,'|||<span').replace(/<\/span>/g,'</span>|||');
            e=c.split('|||');
            each(e,function(a){
                if(a!==''||e.length==1){
                    var b={},tspan=u.createElementNS('http://www.w3.org/2000/svg','tspan');
                    if(styleRegex.test(a)){
                        attr(tspan,'style',a.match(styleRegex)[1].replace(/(;| |^)color([ :])/,'$1fill$2'))
                        }
                        if(hrefRegex.test(a)){
                        attr(tspan,'onclick','location.href=\"'+a.match(hrefRegex)[1]+'\"');
                        css(tspan,{
                            cursor:'pointer'
                        })
                        }
                        a=a.replace(/<(.|\n)*?>/g,'');
                    tspan.appendChild(u.createTextNode(a||' '));
                    if(!spanNo){
                        b.x=parentX
                        }else{
                        b.dx=3
                        }
                        if(d&&!spanNo){
                        b.dy=16
                        }
                        attr(tspan,b);
                    f.appendChild(tspan);
                    spanNo++
                }
            })
        })
    },
crispLine:function(a,b){
    if(a[1]==a[4]){
        a[1]=a[4]=mathRound(a[1])+(b%2/2)
        }
        if(a[2]==a[5]){
        a[2]=a[5]=mathRound(a[2])+(b%2/2)
        }
        return a
    },
path:function(a){
    return this.createElement('path').attr({
        d:a,
        fill:NONE
    })
    },
circle:function(x,y,r){
    var a=typeof x=='object'?x:{
        x:x,
        y:y,
        r:r
    };

    return this.createElement('circle').attr(a)
    },
arc:function(x,y,r,a,b,c){
    if(typeof x=='object'){
        y=x.y;
        r=x.r;
        a=x.innerR;
        b=x.start;
        c=x.end;
        x=x.x
        }
        return this.symbol('arc',x||0,y||0,r||0,{
        innerR:a||0,
        start:b||0,
        end:c||0
        })
    },
rect:function(x,y,a,b,r,c){
    if(arguments.length>1){
        var d=(c||0)%2/2;
        x=mathRound(x||0)+d;
        y=mathRound(y||0)+d;
        a=mathRound((a||0)-2*d);
        b=mathRound((b||0)-2*d)
        }
        var e=typeof x=='object'?x:{
        x:x,
        y:y,
        width:mathMax(a,0),
        height:mathMax(b,0)
        };

    return this.createElement('rect').attr(extend(e,{
        rx:r||e.r,
        ry:r||e.r,
        fill:NONE
    }))
    },
g:function(a){
    return this.createElement('g').attr(defined(a)&&{
        'class':PREFIX+a
        })
    },
image:function(a,x,y,b,c){
    var d=this.createElement('image').attr({
        x:x,
        y:y,
        width:b,
        height:c,
        preserveAspectRatio:NONE
    });
    d.element.setAttributeNS('http://www.w3.org/1999/xlink','href',a);
    return d
    },
symbol:function(b,x,y,c,d){
    var e,symbolFn=this.symbols[b],path=symbolFn&&symbolFn(x,y,c,d),imageRegex=/^url\((.*?)\)$/,imageSrc;
    if(path){
        e=this.path(path);
        extend(e,{
            symbolName:b,
            x:x,
            y:y,
            r:c
        });
        if(d){
            extend(e,d)
            }
        }else if(imageRegex.test(b)){
    imageSrc=b.match(imageRegex)[1];
    e=this.image(imageSrc).attr({
        visibility:HIDDEN
    });
    createElement('img',{
        onload:function(){
            var a=this,size=symbolSizes[a.src]||[a.width,a.height];
            e.attr({
                x:mathRound(x-size[0]/2)+PX,
                y:mathRound(y-size[1]/2)+PX,
                width:size[0],
                height:size[1],
                visibility:'inherit'
            })
            },
        src:imageSrc
    })
    }else{
    e=this.circle(x,y,c)
    }
    return e
},
symbols:{
    'square':function(x,y,a){
        var b=0.707*a;
        return[M,x-b,y-b,L,x+b,y-b,x+b,y+b,x-b,y+b,'Z']
        },
    'triangle':function(x,y,a){
        return[M,x,y-1.33*a,L,x+a,y+0.67*a,x-a,y+0.67*a,'Z']
        },
    'triangle-down':function(x,y,a){
        return[M,x,y+1.33*a,L,x-a,y-0.67*a,x+a,y-0.67*a,'Z']
        },
    'diamond':function(x,y,a){
        return[M,x,y-a,L,x+a,y,x,y+a,x-a,y,'Z']
        },
    'arc':function(x,y,a,b){
        var c=Math.PI,start=b.start,end=b.end-0.000001,innerRadius=b.innerR,cosStart=mathCos(start),sinStart=mathSin(start),cosEnd=mathCos(end),sinEnd=mathSin(end),longArc=b.end-start<c?0:1;
        return[M,x+a*cosStart,y+a*sinStart,'A',a,a,0,longArc,1,x+a*cosEnd,y+a*sinEnd,L,x+innerRadius*cosEnd,y+innerRadius*sinEnd,'A',innerRadius,innerRadius,0,longArc,0,x+innerRadius*cosStart,y+innerRadius*sinStart,'Z']
        }
    },
clipRect:function(x,y,a,b){
    var c,id=PREFIX+idCounter++,clipPath=this.createElement('clipPath').attr({
        id:id
    }).add(this.defs);
    c=this.rect(x,y,a,b,0).add(clipPath);
    c.id=id;
    return c
    },
color:function(b,c,d){
    var e,regexRgba=/^rgba/;
    if(b&&b.linearGradient){
        var f=this,strLinearGradient='linearGradient',linearGradient=b[strLinearGradient],id=PREFIX+idCounter++,gradientObject,stopColor,stopOpacity;
        gradientObject=f.createElement(strLinearGradient).attr({
            id:id,
            gradientUnits:'userSpaceOnUse',
            x1:linearGradient[0],
            y1:linearGradient[1],
            x2:linearGradient[2],
            y2:linearGradient[3]
            }).add(f.defs);
        each(b.stops,function(a){
            if(regexRgba.test(a[1])){
                e=C(a[1]);
                stopColor=e.get('rgb');
                stopOpacity=e.get('a')
                }else{
                stopColor=a[1];
                stopOpacity=1
                }
                f.createElement('stop').attr({
                offset:a[0],
                'stop-color':stopColor,
                'stop-opacity':stopOpacity
            }).add(gradientObject)
            });
        return'url('+this.url+'#'+id+')'
        }else if(regexRgba.test(b)){
        e=C(b);
        attr(c,d+'-opacity',e.get('a'));
        return e.get('rgb')
        }else{
        return b
        }
    },
text:function(a,x,y,b,c,d){
    b=b||{};

    d=d||'left';
    c=c||0;
    var e,css,fill=b.color||'#000000',defaultChartStyle=defaultOptions.chart.style;
    x=mathRound(pick(x,0));
    y=mathRound(pick(y,0));
    extend(b,{
        fontFamily:b.fontFamily||defaultChartStyle.fontFamily,
        fontSize:b.fontSize||defaultChartStyle.fontSize
        });
    css=serializeCSS(b);
    e={
        x:x,
        y:y,
        text:a,
        fill:fill,
        style:css.replace(/"/g,"'")
        };

    if(c||d!='left'){
        e=extend(e,{
            'text-anchor':{
                left:'start',
                center:'middle',
                right:'end'
            }
            [d],
            transform:'rotate('+c+' '+x+' '+y+')'
            })
        }
        return this.createElement('text').attr(e)
    }
};

var E;
if(!hasSVG){
    var F=extendClass(SVGElement,{
        init:function(a,b){
            var c=['<',b,' filled="f" stroked="f"'],style=['position: ',ABSOLUTE,';'];
            if(b=='shape'||b==DIV){
                style.push('left:0;top:0;width:10px;height:10px')
                }
                c.push(' style="',style.join(''),'"/>');
            if(b){
                c=b==DIV||b=='span'||b=='img'?c.join(''):a.prepVML(c);
                this.element=createElement(c)
                }
                this.renderer=a
            },
        add:function(a){
            var b=this,renderer=b.renderer,element=b.element,box=renderer.box,inverted=a&&a.inverted,parentStyle,parentNode=a?a.element||a:box;
            if(inverted){
                parentStyle=parentNode.style;
                css(element,{
                    flip:'x',
                    left:parseInt(parentStyle.width,10)-10,
                    top:parseInt(parentStyle.height,10)-10,
                    rotation:-90
                })
                }
                parentNode.appendChild(element);
            return b
            },
        attr:function(b,c){
            var d,value,i,element=this.element,elemStyle=element.style,nodeName=element.nodeName,renderer=this.renderer,symbolName=this.symbolName,hasSetSymbolSize,shadows=this.shadows,documentMode=u.documentMode,skipAttr,ret=this;
            if(typeof b=='string'&&defined(c)){
                d=b;
                b={};

                b[d]=c
                }
                if(typeof b=='string'){
                d=b;
                if(d=='strokeWidth'||d=='stroke-width'){
                    ret=element.strokeweight
                    }else{
                    ret=pick(this[d],parseInt(elemStyle[{
                        x:'left',
                        y:'top'
                    }
                    [d]||d],10))
                    }
                }else{
            for(d in b){
                value=b[d];
                skipAttr=false;
                if(symbolName&&/^(x|y|r|start|end|width|height|innerR)/.test(d)){
                    if(!hasSetSymbolSize){
                        this.symbolAttr(b);
                        hasSetSymbolSize=true
                        }
                        skipAttr=true
                    }else if(d=='d'){
                    i=value.length;
                    var e=[];
                    while(i--){
                        if(typeof value[i]=='number'){
                            e[i]=mathRound(value[i]*10)-5
                            }else if(value[i]=='Z'){
                            e[i]='x'
                            }else{
                            e[i]=value[i]
                            }
                        }
                    value=e.join(' ')||'x';
                element.path=value;
                if(shadows){
                    i=shadows.length;
                    while(i--){
                        shadows[i].path=value
                        }
                    }
                skipAttr=true
            }else if(d=='zIndex'||d=='visibility'){
                elemStyle[d]=value;
                if(documentMode==8&&d=='visibility'&&nodeName=='DIV'){
                    each(element.childNodes,function(a){
                        css(a,{
                            visibility:value
                        })
                        })
                    }
                    skipAttr=true
                }else if(/^(width|height)$/.test(d)){
                elemStyle[d]=value;
                if(this.updateClipping){
                    this.updateClipping()
                    }
                    skipAttr=true
                }else if(/^(x|y)$/.test(d)){
                if(d=='y'&&element.tagName=='SPAN'&&element.lineHeight){
                    value-=element.lineHeight
                    }
                    elemStyle[{
                    x:'left',
                    y:'top'
                }
                [d]]=value
                }else if(d=='class'){
                element.className=value
                }else if(d=='stroke'){
                value=renderer.color(value,element,d);
                d='strokecolor'
                }else if(d=='stroke-width'||d=='strokeWidth'){
                element.stroked=value?true:false;
                d='strokeweight';
                if(typeof value=='number'){
                    value+=PX
                    }
                }else if(d=='fill'){
                if(nodeName=='SPAN'){
                    elemStyle.color=value
                    }else{
                    element.filled=value!=NONE?true:false;
                    value=renderer.color(value,element,d);
                    d='fillcolor'
                    }
                }else if(d=='translateX'||d=='translateY'){
            this[d]=c;
            this.updateTransform();
            skipAttr=true
            }
            if(shadows&&d=='visibility'){
            i=shadows.length;
            while(i--){
                shadows[i].style[d]=value
                }
            }
        if(d=='text'){
        element.innerHTML=value
        }else if(!skipAttr){
        if(documentMode==8){
            element[d]=value
            }else{
            attr(element,d,value)
            }
        }
    }
}
return ret
},
clip:function(a){
    var b=this,clipMembers=a.members,index=clipMembers.length;
    clipMembers.push(b);
    b.destroyClip=function(){
        clipMembers.splice(index,1)
        };

    return b.css(a.getCSS(b.inverted))
    },
css:function(a){
    var b=this;
    css(b.element,a);
    return b
    },
destroy:function(){
    var a=this;
    if(a.destroyClip){
        a.destroyClip()
        }
        SVGElement.prototype.destroy.apply(this)
    },
empty:function(){
    var a=this.element,childNodes=a.childNodes,i=childNodes.length,node;
    while(i--){
        node=childNodes[i];
        node.parentNode.removeChild(node)
        }
    },
getBBox:function(){
    var a=this.element,ret,hasOffsetWidth=a.offsetWidth,origParentNode=a.parentNode;
    if(!hasOffsetWidth){
        u.body.appendChild(a)
        }
        ret={
        x:a.offsetLeft,
        y:a.offsetTop,
        width:a.offsetWidth,
        height:a.offsetHeight
        };

    if(!hasOffsetWidth){
        if(origParentNode){
            origParentNode.appendChild(a)
            }else{
            u.body.removeChild(a)
            }
        }
    return ret
},
on:function(b,c){
    this.element['on'+b]=function(){
        var a=win.event;
        a.target=a.srcElement;
        c(a)
        };

    return this
    },
updateTransform:function(){
    var a=this,translateX=a.translateX||0,translateY=a.translateY||0;
    if(translateX||translateY){
        a.css({
            left:translateX,
            top:translateY
        })
        }
    },
shadow:function(a){
    var b=[],i,element=this.element,renderer=this.renderer,shadow,elemStyle=element.style,markup,path=element.path;
    if(''+element.path==''){
        path='x'
        }
        if(a){
        for(i=1;i<=3;i++){
            markup=['<shape isShadow="true" strokeweight="',(7-2*i),'" filled="false" path="',path,'" coordsize="100,100" style="',element.style.cssText,'" />'];
            shadow=createElement(renderer.prepVML(markup),null,{
                left:parseInt(elemStyle.left,10)+1,
                top:parseInt(elemStyle.top,10)+1
                });
            markup=['<stroke color="black" opacity="',(0.05*i),'"/>'];
            createElement(renderer.prepVML(markup),null,null,shadow);
            element.parentNode.insertBefore(shadow,element);
            b.push(shadow)
            }
            this.shadows=b
        }
        return this
    }
});
E=function(){
    this.init.apply(this,arguments)
    };

E.prototype=merge(D.prototype,{
    isIE8:userAgent.indexOf('MSIE 8.0')>-1,
    init:function(a,b,c){
        this.width=b;
        this.height=c;
        this.box=createElement(DIV,null,{
            width:b+PX,
            height:c+PX
            },a);
        this.Element=F;
        if(!u.namespaces.hcv){
            u.namespaces.add('hcv','urn:schemas-microsoft-com:vml');
            u.createStyleSheet().cssText='hcv\\:fill, hcv\\:path, hcv\\:textpath, hcv\\:shape, hcv\\:stroke, hcv\\:line '+'{ behavior:url(#default#VML); display: inline-block; } '
        }
    },
clipRect:function(x,y,c,d){
    var e=this.createElement();
    return extend(e,{
        members:[],
        element:{
            style:{
                left:x,
                top:y,
                width:c,
                height:d
            }
        },
    getCSS:function(a){
        var b=e.element.style,top=b.top,left=b.left,right=left+b.width,bottom=top+b.height,ret={
            clip:'rect('+(a?left:top)+'px,'+(a?bottom:right)+'px,'+(a?right:bottom)+'px,'+(a?top:left)+'px)'
            };

        if(!a&&u.documentMode==8){
            extend(ret,{
                width:right+PX,
                height:bottom+PX
                })
            }
            return ret
        },
    updateClipping:function(){
        each(e.members,function(a){
            a.css(e.getCSS(a.inverted))
            })
        }
    })
},
color:function(b,c,d){
    var e,regexRgba=/^rgba/,markup;
    if(b&&b.linearGradient){
        var f,stopOpacity,linearGradient=b.linearGradient,angle,color1,opacity1,color2,opacity2;
        each(b.stops,function(a,i){
            if(regexRgba.test(a[1])){
                e=C(a[1]);
                f=e.get('rgb');
                stopOpacity=e.get('a')
                }else{
                f=a[1];
                stopOpacity=1
                }
                if(!i){
                color1=f;
                opacity1=stopOpacity
                }else{
                color2=f;
                opacity2=stopOpacity
                }
            });
    angle=90-math.atan((linearGradient[3]-linearGradient[1])/(linearGradient[2]-linearGradient[0]))*180/math.PI;
    markup=['<',d,' colors="0% ',color1,',100% ',color2,'" angle="',angle,'" opacity="',opacity2,'" o:opacity2="',opacity1,'" type="gradient" focus="100%" />'];
    createElement(this.prepVML(markup),null,null,c)
    }else if(regexRgba.test(b)){
    e=C(b);
    markup=['<',d,' opacity="',e.get('a'),'"/>'];
    createElement(this.prepVML(markup),null,null,c);
    return e.get('rgb')
    }else{
    return b
    }
},
prepVML:function(a){
    var b='display:inline-block;behavior:url(#default#VML);',isIE8=this.isIE8;
    try{
        a=a.join('')
        }catch(e){
        var s='',i=0;
        for(i;i<a.length;i++){
            s+=a[i]
            }
            a=s
        }
        if(isIE8){
        a=a.replace('/>',' xmlns="urn:schemas-microsoft-com:vml" />');
        if(a.indexOf('style="')==-1){
            a=a.replace('/>',' style="'+b+'" />')
            }else{
            a=a.replace('style="','style="'+b)
            }
        }else{
    a=a.replace('<','<hcv:')
    }
    return a
},
text:function(a,x,y,b,c,d){
    b=b||{};

    d=d||'left';
    c=c||0;
    var e,elem,spanWidth,lineHeight=mathRound(parseInt(b.fontSize||12,10)*1.2),defaultChartStyle=defaultOptions.chart.style;
    x=mathRound(x);
    y=mathRound(y);
    extend(b,{
        color:b.color||'#000000',
        whiteSpace:'nowrap',
        fontFamily:b.fontFamily||defaultChartStyle.fontFamily,
        fontSize:b.fontSize||defaultChartStyle.fontSize
        });
    if(!c){
        e=this.createElement('span').attr({
            x:x,
            y:y-lineHeight,
            text:a
        });
        elem=e.element;
        elem.lineHeight=lineHeight;
        css(elem,b);
        if(d!='left'){
            spanWidth=e.getBBox().width;
            css(elem,{
                left:(x-spanWidth/{
                    right:1,
                    center:2
                }
                [d])+PX
                })
            }
        }else{
    var f=(c||0)*math.PI*2/360,costheta=mathCos(f),sintheta=mathSin(f),length=10,baselineCorrection=lineHeight*0.3,left=d=='left',right=d=='right',x1=left?x:x-length*costheta,x2=right?x:x+length*costheta,y1=left?y:y-length*sintheta,y2=right?y:y+length*sintheta;
    x1+=baselineCorrection*sintheta;
    x2+=baselineCorrection*sintheta;
    y1-=baselineCorrection*costheta;
    y2-=baselineCorrection*costheta;
    if(mathAbs(x1-x2)<0.1){
        x1+=0.1
        }
        if(mathAbs(y1-y2)<0.1){
        y1+=0.1
        }
        e=this.createElement('line').attr({
        from:x1+', '+y1,
        to:x2+', '+y2
        });
    elem=e.element;
    createElement('hcv:fill',{
        on:true,
        color:b.color
        },null,elem);
    createElement('hcv:path',{
        textpathok:true
    },null,elem);
    createElement('<hcv:textpath style="v-text-align:'+d+';'+serializeCSS(b).replace(/"/g,"'")+'" on="true" string="'+a.toString().replace(/<br[^>]?>/g,'\n')+'">',null,null,elem)
    }
    return e
},
path:function(a){
    return this.createElement('shape').attr({
        coordsize:'100 100',
        d:a
    })
    },
circle:function(x,y,r){
    return this.path(this.symbols.circle(x,y,r))
    },
g:function(a){
    var b,attribs;
    if(a){
        attribs={
            'className':PREFIX+a,
            'class':PREFIX+a
            }
        }
    b=this.createElement(DIV).attr(attribs);
return b
},
image:function(a,x,y,b,c){
    return this.createElement('img').attr({
        src:a
    }).css({
        left:x,
        top:y,
        width:b,
        height:c
    })
    },
rect:function(x,y,a,b,r,c){
    if(arguments.length>1){
        var d=(c||0)%2/2;
        x=mathRound(x||0)+d;
        y=mathRound(y||0)+d;
        a=mathRound((a||0)-2*d);
        b=mathRound((b||0)-2*d)
        }
        if(typeof x=='object'){
        y=x.y;
        a=x.width;
        b=x.height;
        r=x.r;
        x=x.x
        }
        return this.symbol('rect',x||0,y||0,r||0,{
        width:a||0,
        height:b||0
        })
    },
symbol:function(b,x,y,c){
    var d,imageRegex=/^url\((.*?)\)$/;
    if(imageRegex.test(b)){
        d=this.createElement('img').attr({
            onload:function(){
                var a=this,size=[a.width,a.height];
                css(a,{
                    left:mathRound(x-size[0]/2),
                    top:mathRound(y-size[1]/2)
                    })
                },
            src:b.match(imageRegex)[1]
            })
        }else{
        d=D.prototype.symbol.apply(this,arguments)
        }
        return d
    },
symbols:{
    arc:function(x,y,a,b){
        var c=b.start,optionsEnd=b.end,end=optionsEnd-c==2*Math.PI?optionsEnd-0.001:optionsEnd,cosStart=mathCos(c),sinStart=mathSin(c),cosEnd=mathCos(end),sinEnd=mathSin(end),innerRadius=b.innerR;
        if(optionsEnd-c===0){
            return['x']
            }
            return['wa',x-a,y-a,x+a,y+a,x+a*cosStart,y+a*sinStart,x+a*cosEnd,y+a*sinEnd,'at',x-innerRadius,y-innerRadius,x+innerRadius,y+innerRadius,x+innerRadius*cosEnd,y+innerRadius*sinEnd,x+innerRadius*cosStart,y+innerRadius*sinStart,'x','e']
        },
    circle:function(x,y,r){
        return['wa',x-r,y-r,x+r,y+r,x+r,y,x+r,y,'e']
        },
    rect:function(a,b,r,c){
        var d=c.width,height=c.height,right=a+d,bottom=b+height;
        r=mathMin(r,d,height);
        return[M,a+r,b,L,right-r,b,'wa',right-2*r,b,right,b+2*r,right-r,b,right,b+r,L,right,bottom-r,'wa',right-2*r,bottom-2*r,right,bottom,right,bottom-r,right-r,bottom,L,a+r,bottom,'wa',a,bottom-2*r,a+2*r,bottom,a+r,bottom,a,bottom-r,L,a,b+r,'wa',a,b,a+2*r,b+2*r,a,b+r,a+r,b,'x','e']
        }
    }
})
}
var G=hasSVG?D:E;
function Chart(n,o){
    A=merge(A,defaultOptions.xAxis);
    defaultYAxisOptions=merge(defaultYAxisOptions,defaultOptions.yAxis);
    defaultOptions.xAxis=defaultOptions.yAxis=null;
    n=merge(defaultOptions,n);
    var p=n.chart,optionsMargin=p.margin,margin=typeof optionsMargin=='number'?[optionsMargin,optionsMargin,optionsMargin,optionsMargin]:optionsMargin,plotTop=pick(p.marginTop,margin[0]),marginRight=pick(p.marginRight,margin[1]),marginBottom=pick(p.marginBottom,margin[2]),plotLeft=pick(p.marginLeft,margin[3]),renderTo,renderToClone,container,containerId,chartWidth,chartHeight,chart=this,chartEvents=p.events,eventType,getAlignment,isInsidePlot,tooltip,mouseIsDown,loadingLayer,loadingShown,plotHeight,plotWidth,plotSizeX,plotSizeY,tracker,trackerGroup,legend,position,hasCartesianSeries=p.showAxes,axes=[],maxTicks,series=[],inverted,renderer,tooltipTick,tooltipInterval,zoom,zoomOut;
    function Axis(j,k){
        var l=k.isX,opposite=k.opposite,horiz=inverted?!l:l,stacks={
            bar:{},
            column:{},
            area:{},
            areaspline:{},
            line:{}
    };

    k=merge(l?A:defaultYAxisOptions,horiz?(opposite?defaultTopAxisOptions:defaultBottomAxisOptions):(opposite?defaultRightAxisOptions:defaultLeftAxisOptions),k);
    var m=this,isDatetimeAxis=k.type=='datetime',offset=k.offset||0,xOrY=l?'x':'y',axisLength=horiz?plotWidth:plotHeight,transA,transB=horiz?plotLeft:marginBottom,axisGroup,gridGroup,dataMin,dataMax,associatedSeries,userSetMin,userSetMax,max=null,min=null,minPadding=k.minPadding,maxPadding=k.maxPadding,isLinked=defined(k.linkedTo),ignoreMinPadding,ignoreMaxPadding,usePercentage,events=k.events,eventType,plotBands=k.plotBands||[],plotLines=k.plotLines||[],tickInterval,minorTickInterval,magnitude,tickPositions,tickAmount,dateTimeLabelFormat,labelFormatter=k.labels.formatter||function(){
        var a=this.value;
        return dateTimeLabelFormat?dateFormat(dateTimeLabelFormat,a):a
        },categories=k.categories||(l&&j.columnCount),reversed=k.reversed,tickmarkOffset=(categories&&k.tickmarkPlacement=='between')?0.5:0;
    function getSeriesExtremes(){
        var f=[],run;
        dataMin=dataMax=null;
        associatedSeries=[];
        each(series,function(d){
            run=false;
            each(['xAxis','yAxis'],function(a){
                if(d.isCartesian&&(a=='xAxis'&&l||a=='yAxis'&&!l)&&((d.options[a]==k.index)||(d.options[a]===UNDEFINED&&k.index===0))){
                    d[a]=m;
                    associatedSeries.push(d);
                    run=true
                    }
                });
        if(!d.visible&&p.ignoreHiddenSeries){
            run=false
            }
            if(run){
            var e,typeStack;
            if(!l){
                e=d.options.stacking;
                usePercentage=e=='percent';
                if(e){
                    typeStack=f[d.type]||[];
                    f[d.type]=typeStack
                    }
                    if(usePercentage){
                    dataMin=0;
                    dataMax=99
                    }
                }
            if(d.isCartesian){
            each(d.data,function(a,i){
                var b=a.x,pointY=a.y;
                if(dataMin===null){
                    dataMin=dataMax=a[xOrY]
                    }
                    if(l){
                    if(b>dataMax){
                        dataMax=b
                        }else if(b<dataMin){
                        dataMin=b
                        }
                    }else if(defined(pointY)){
                if(e){
                    typeStack[b]=typeStack[b]?typeStack[b]+pointY:pointY
                    }
                    var c=typeStack?typeStack[b]:pointY;
                if(!usePercentage){
                    if(c>dataMax){
                        dataMax=c
                        }else if(c<dataMin){
                        dataMin=c
                        }
                    }
                if(e){
                stacks[d.type][b]={
                    total:c,
                    cum:c
                }
            }
            }
        });
if(/(area|column|bar)/.test(d.type)&&!l){
    if(dataMin>=0){
        dataMin=0;
        ignoreMinPadding=true
        }else if(dataMax<0){
        dataMax=0;
        ignoreMaxPadding=true
        }
    }
}
}
})
}
function translate(a,b,c){
    var d=1,cvsOffset=0,returnValue;
    if(c){
        d*=-1;
        cvsOffset=axisLength
        }
        if(reversed){
        d*=-1;
        cvsOffset-=d*axisLength
        }
        if(min===UNDEFINED){
        returnValue=null
        }else if(b){
        if(reversed){
            a=axisLength-a
            }
            returnValue=a/transA+min
        }else{
        returnValue=d*(a-min)*transA+cvsOffset
        }
        return returnValue
    }
    function drawPlotLine(a,b,c){
    if(c){
        var d,y1,x2,y2,translatedValue=translate(a),skip;
        d=x2=translatedValue+transB;
        y1=y2=chartHeight-translatedValue-transB;
        if(horiz){
            y1=plotTop;
            y2=chartHeight-marginBottom;
            if(d<plotLeft||d>plotLeft+plotWidth){
                skip=true
                }
            }else{
        d=plotLeft;
        x2=chartWidth-marginRight;
        if(y1<plotTop||y1>plotTop+plotHeight){
            skip=true
            }
        }
    if(!skip){
    renderer.path(renderer.crispLine([M,d,y1,L,x2,y2],c)).attr({
        stroke:b,
        'stroke-width':c
    }).add(gridGroup)
    }
}
}
function drawPlotBand(a,b,c){
    a=mathMax(a,min);
    b=mathMin(b,max);
    var d=(b-a)*transA;
    drawPlotLine(a+(b-a)/2,c,d)
    }
    function addTick(a,b,c,d,e,f,g){
    var h,y1,x2,y2,str,labelOptions=k.labels;
    if(b=='inside'){
        e=-e
        }
        if(opposite){
        e=-e
        }
        h=x2=translate(a+tickmarkOffset)+transB;
    y1=y2=chartHeight-translate(a+tickmarkOffset)-transB;
    if(horiz){
        y1=chartHeight-marginBottom-(opposite?plotHeight:0)+offset;
        y2=y1+e
        }else{
        h=plotLeft+(opposite?plotWidth:0)+offset;
        x2=h-e
        }
        if(d){
        renderer.path(renderer.crispLine([M,h,y1,L,x2,y2],d)).attr({
            stroke:c,
            'stroke-width':d
        }).add(axisGroup)
        }
        if(f&&labelOptions.enabled){
        str=labelFormatter.call({
            index:g,
            isFirst:a==tickPositions[0],
            isLast:a==tickPositions[tickPositions.length-1],
            dateTimeLabelFormat:dateTimeLabelFormat,
            value:(categories&&categories[a]?categories[a]:a)
            });
        if(str||str===0){
            h=h+labelOptions.x-(tickmarkOffset&&horiz?tickmarkOffset*transA*(reversed?-1:1):0);
            y1=y1+labelOptions.y-(tickmarkOffset&&!horiz?tickmarkOffset*transA*(reversed?1:-1):0);
            renderer.text(str,h,y1,labelOptions.style,labelOptions.rotation,labelOptions.align).add(axisGroup)
            }
        }
}
function normalizeTickInterval(a,b){
    var c;
    magnitude=b?1:math.pow(10,mathFloor(math.log(a)/math.LN10));
    c=a/magnitude;
    if(!b){
        b=[1,2,2.5,5,10];
        if(k.allowDecimals===false){
            if(magnitude==1){
                b=[1,2,5,10]
                }else if(magnitude<=0.1){
                b=[1/magnitude]
                }
            }
    }
for(var i=0;i<b.length;i++){
    a=b[i];
    if(c<=(b[i]+(b[i+1]||b[i]))/2){
        break
    }
}
a*=magnitude;
return a
}
function setDateTimeTickPositions(){
    tickPositions=[];
    var i,useUTC=defaultOptions.global.useUTC,oneSecond=1000/timeFactor,oneMinute=60000/timeFactor,oneHour=3600000/timeFactor,oneDay=24*3600000/timeFactor,oneWeek=7*24*3600000/timeFactor,oneMonth=30*24*3600000/timeFactor,oneYear=31556952000/timeFactor,units=[['second',oneSecond,[1,2,5,10,15,30]],['minute',oneMinute,[1,2,5,10,15,30]],['hour',oneHour,[1,2,3,4,6,8,12]],['day',oneDay,[1,2]],['week',oneWeek,[1,2]],['month',oneMonth,[1,2,3,4,6]],['year',oneYear,null]],unit=units[6],interval=unit[1],multiples=unit[2];
    for(i=0;i<units.length;i++){
        unit=units[i];
        interval=unit[1];
        multiples=unit[2];
        if(units[i+1]){
            var a=(interval*multiples[multiples.length-1]+units[i+1][1])/2;
            if(tickInterval<=a){
                break
            }
        }
    }
    if(interval==oneYear&&tickInterval<5*interval){
    multiples=[1,2,5]
    }
    var b=normalizeTickInterval(tickInterval/interval,multiples),minYear,minDate=new Date(min*timeFactor);
minDate.setMilliseconds(0);
if(interval>=oneSecond){
    minDate.setSeconds(interval>=oneMinute?0:b*mathFloor(minDate.getSeconds()/b))
    }
    if(interval>=oneMinute){
    minDate[setMinutes](interval>=oneHour?0:b*mathFloor(minDate[getMinutes]()/b))
    }
    if(interval>=oneHour){
    minDate[setHours](interval>=oneDay?0:b*mathFloor(minDate[getHours]()/b))
    }
    if(interval>=oneDay){
    minDate[setDate](interval>=oneMonth?1:b*mathFloor(minDate[getDate]()/b))
    }
    if(interval>=oneMonth){
    minDate[setMonth](interval>=oneYear?0:b*mathFloor(minDate[getMonth]()/b));
    minYear=minDate[getFullYear]()
    }
    if(interval>=oneYear){
    minYear-=minYear%b;
    minDate[setFullYear](minYear)
    }
    if(interval==oneWeek){
    minDate[setDate](minDate[getDate]()-minDate[getDay]()+k.startOfWeek)
    }
    i=1;
minYear=minDate[getFullYear]();
var c=minDate.getTime()/timeFactor,minMonth=minDate[getMonth](),minDateDate=minDate[getDate]();
while(c<max&&i<plotWidth){
    tickPositions.push(c);
    if(interval==oneYear){
        c=makeTime(minYear+i*b,0)/timeFactor
        }else if(interval==oneMonth){
        c=makeTime(minYear,minMonth+i*b)/timeFactor
        }else if(!useUTC&&(interval==oneDay||interval==oneWeek)){
        c=makeTime(minYear,minMonth,minDateDate+i*b*(interval==oneDay?1:7))
        }else{
        c+=interval*b
        }
        i++
}
tickPositions.push(c);
dateTimeLabelFormat=k.dateTimeLabelFormats[unit[0]]
}
function correctFloat(a){
    var b=(magnitude<1?mathRound(1/magnitude):1)*10;
    return mathRound(a*b)/b
    }
    function setLinearTickPositions(){
    var i,roundedMin=mathFloor(min/tickInterval)*tickInterval,roundedMax=mathCeil(max/tickInterval)*tickInterval;
    tickPositions=[];
    i=correctFloat(roundedMin);
    while(i<=roundedMax){
        tickPositions.push(i);
        i=correctFloat(i+tickInterval)
        }
        if(categories){
        min-=0.5;
        max+=0.5
        }
    }
function setTickPositions(){
    if(isDatetimeAxis){
        setDateTimeTickPositions()
        }else{
        setLinearTickPositions()
        }
        var a=tickPositions[0],roundedMax=tickPositions[tickPositions.length-1];
    if(k.startOnTick){
        min=a
        }else if(min>a){
        tickPositions.shift()
        }
        if(k.endOnTick){
        max=roundedMax
        }else if(max<roundedMax){
        tickPositions.pop()
        }
    }
function adjustTickAmount(){
    if(!isDatetimeAxis&&!categories){
        var a=tickAmount,calculatedTickAmount=tickPositions.length;
        tickAmount=maxTicks[xOrY];
        if(calculatedTickAmount<tickAmount){
            while(tickPositions.length<tickAmount){
                tickPositions.push(correctFloat(tickPositions[tickPositions.length-1]+tickInterval))
                }
                transA*=(calculatedTickAmount-1)/(tickAmount-1)
            }
            if(defined(a)&&tickAmount!=a){
            m.isDirty=true
            }
        }
}
function setScale(){
    var a,type,i,oldMin=min,oldMax=max,maxZoom=k.maxZoom,zoomOffset;
    getSeriesExtremes();
    min=pick(userSetMin,k.min,dataMin);
    max=pick(userSetMax,k.max,dataMax);
    if(isLinked){
        var b=j[l?'xAxis':'yAxis'][k.linkedTo],linkedParentExtremes=b.getExtremes();
        min=pick(linkedParentExtremes.min,linkedParentExtremes.dataMin);
        max=pick(linkedParentExtremes.max,linkedParentExtremes.dataMax)
        }
        if(max-min<maxZoom){
        zoomOffset=(maxZoom-max+min)/2;
        min=mathMax(min-zoomOffset,pick(k.min,min-zoomOffset));
        max=mathMin(min+maxZoom,pick(k.max,min+maxZoom))
        }
        if(!categories&&!usePercentage&&!isLinked&&defined(min)&&defined(max)){
        a=(max-min)||1;
        if(!defined(k.min)&&!defined(userSetMin)&&minPadding&&(dataMin<0||!ignoreMinPadding)){
            min-=a*minPadding
            }
            if(!defined(k.max)&&!defined(userSetMax)&&maxPadding&&(dataMax>0||!ignoreMaxPadding)){
            max+=a*maxPadding
            }
        }
    if(categories||min==max){
    tickInterval=1
    }else{
    tickInterval=pick(k.tickInterval,(max-min)*k.tickPixelInterval/axisLength)
    }
    if(!isDatetimeAxis&&!defined(k.tickInterval)){
    tickInterval=normalizeTickInterval(tickInterval)
    }
    minorTickInterval=k.minorTickInterval==='auto'&&tickInterval?tickInterval/5:k.minorTickInterval;
setTickPositions();
transA=axisLength/((max-min)||1);
if(!maxTicks){
    maxTicks={
        x:0,
        y:0
    }
}
if(!isDatetimeAxis&&tickPositions.length>maxTicks[xOrY]){
    maxTicks[xOrY]=tickPositions.length
    }
    if(!l){
    for(type in stacks){
        for(i in stacks[type]){
            stacks[type][i].cum=stacks[type][i].total
            }
        }
        }
    if(!m.isDirty){
    m.isDirty=(min!=oldMin||max!=oldMax)
    }
}
function setExtremes(a,b,c){
    c=pick(c,true);
    fireEvent(m,'setExtremes',{
        min:a,
        max:b
    },function(){
        if(categories){
            if(a<0){
                a=0
                }
                if(b>categories.length-1){
                b=categories.length-1
                }
            }
        userSetMin=a;
    userSetMax=b;
    if(c){
        j.redraw()
        }
    })
}
function getExtremes(){
    return{
        min:min,
        max:max,
        dataMin:dataMin,
        dataMax:dataMax
    }
}
function getThreshold(a,b){
    if(b){
        return translate(max,0,1)
        }else{
        if(min>a){
            a=min
            }else if(max<a){
            a=max
            }
            return translate(a,0,1)
        }
    }
function addPlotBandOrLine(a){
    var b=a.width,collection=b?plotLines:plotBands;
    collection.push(a);
    if(b){
        drawPlotLine(a.value,a.color,a.width)
        }else{
        drawPlotBand(a.from,a.to,a.color)
        }
    }
function render(){
    var c=k.title,alternateGridColor=k.alternateGridColor,minorTickWidth=k.minorTickWidth,lineWidth=k.lineWidth,lineLeft,lineTop,tickmarkPos,hasData=associatedSeries.length&&defined(min)&&defined(max);
    if(!axisGroup){
        axisGroup=renderer.g('axis').attr({
            zIndex:7
        }).add();
        gridGroup=renderer.g('grid').attr({
            zIndex:1
        }).add()
        }else{
        axisGroup.empty();
        gridGroup.empty()
        }
        if(hasData||isLinked){
        if(alternateGridColor){
            each(tickPositions,function(a,i){
                if(i%2===0&&a<max){
                    drawPlotBand(a,tickPositions[i+1]!==UNDEFINED?tickPositions[i+1]:max,alternateGridColor)
                    }
                })
        }
        each(plotBands,function(a){
        drawPlotBand(a.from,a.to,a.color)
        });
    if(minorTickInterval&&!categories){
        for(var i=min;i<=max;i+=minorTickInterval){
            drawPlotLine(i,k.minorGridLineColor,k.minorGridLineWidth);
            if(minorTickWidth){
                addTick(i,k.minorTickPosition,k.minorTickColor,minorTickWidth,k.minorTickLength)
                }
            }
        }
    each(tickPositions,function(a,b){
    tickmarkPos=a+tickmarkOffset;
    drawPlotLine(tickmarkPos,k.gridLineColor,k.gridLineWidth);
    addTick(a,k.tickPosition,k.tickColor,k.tickWidth,k.tickLength,!((a==min&&!k.showFirstLabel)||(a==max&&!k.showLastLabel)),b)
    });
each(plotLines,function(a){
    drawPlotLine(a.value,a.color,a.width)
    })
}
if(!m.hasRenderedLine&&lineWidth){
    lineLeft=plotLeft+(opposite?plotWidth:0)+offset;
    lineTop=chartHeight-marginBottom-(opposite?plotHeight:0)+offset;
    renderer.path(renderer.crispLine([M,horiz?plotLeft:lineLeft,horiz?lineTop:plotTop,L,horiz?chartWidth-marginRight:lineLeft,horiz?lineTop:chartHeight-marginBottom],lineWidth)).attr({
        stroke:k.lineColor,
        'stroke-width':lineWidth,
        zIndex:7
    }).add();
    m.hasRenderedLine=true
    }
    if(!m.hasRenderedTitle&&!m.axisTitle&&c&&c.text){
    var d=horiz?plotLeft:plotTop;
    var e={
        low:d+(horiz?0:axisLength),
        middle:d+axisLength/2,
        high:d+(horiz?axisLength:0)
        }
        [c.align];
    var f=(horiz?plotTop+plotHeight:plotLeft)+(horiz?1:-1)*(opposite?-1:1)*c.margin-(isIE?parseInt(c.style.fontSize||12,10)/3:0);
    m.axisTitle=renderer.text(c.text,(horiz?e:f+(opposite?plotWidth:0)+offset)+(c.x||0),(horiz?f-(opposite?plotHeight:0)+offset:e)+(c.y||0),c.style,c.rotation||0,{
        low:'left',
        middle:'center',
        high:'right'
    }
    [c.align]).attr({
        zIndex:7
    }).add();
    m.hasRenderedTitle=true
    }
    m.isDirty=false
}
function removePlotBandOrLine(b){
    each([plotBands,plotLines],function(a){
        for(var i=0;i<a.length;i++){
            if(a[i].id==b){
                a.splice(i,1);
                break
            }
        }
        });
render()
}
function redraw(){
    if(tracker.resetTracker){
        tracker.resetTracker()
        }
        render();
    each(associatedSeries,function(a){
        a.isDirty=true
        })
    }
    function setCategories(b,c){
    m.categories=categories=b;
    each(associatedSeries,function(a){
        a.translate();
        a.setTooltipPoints(true)
        });
    m.isDirty=true;
    if(pick(c,true)){
        redraw()
        }
    }
if(inverted&&l&&reversed===UNDEFINED){
    reversed=true
    }
    if(!opposite){
    offset*=-1
    }
    if(horiz){
    offset*=-1
    }
    extend(m,{
    addPlotBand:addPlotBandOrLine,
    addPlotLine:addPlotBandOrLine,
    adjustTickAmount:adjustTickAmount,
    categories:categories,
    getExtremes:getExtremes,
    getThreshold:getThreshold,
    isXAxis:l,
    options:k,
    render:render,
    setExtremes:setExtremes,
    setScale:setScale,
    setCategories:setCategories,
    translate:translate,
    redraw:redraw,
    removePlotBand:removePlotBandOrLine,
    removePlotLine:removePlotBandOrLine,
    reversed:reversed,
    stacks:stacks
});
for(eventType in events){
    addEvent(m,eventType,events[eventType])
    }
    setScale()
}
function Toolbar(f){
    var g={};

    function add(a,b,c,d){
        if(!g[a]){
            var e=renderer.text(b,plotLeft+plotWidth-20,plotTop+30,n.toolbar.itemStyle,0,'right').on('click',d).attr({
                zIndex:20
            }).add();
            g[a]=e
            }
        }
    function remove(a){
    discardElement(g[a].element);
    g[a]=null
    }
    return{
    add:add,
    remove:remove
}
}
function Tooltip(c){
    var d,borderWidth=c.borderWidth,style=c.style,padding=parseInt(style.padding,10),boxOffLeft=borderWidth+padding,tooltipIsHidden=true,boxWidth,boxHeight,currentX=0,currentY=0;
    style.padding=0;
    var e=renderer.g('tooltip').attr({
        zIndex:8
    }).add(),box=renderer.rect(boxOffLeft,boxOffLeft,0,0,c.borderRadius,borderWidth).attr({
        fill:c.backgroundColor,
        'stroke-width':borderWidth
    }).add(e).shadow(c.shadow),label=renderer.text('',padding+boxOffLeft,parseInt(style.fontSize,10)+padding+boxOffLeft).attr({
        zIndex:1
    }).css(style).add(e);
    function move(a,b){
        currentX=tooltipIsHidden?a:(2*currentX+a)/3;
        currentY=tooltipIsHidden?b:(currentY+b)/2;
        e.translate(currentX,currentY);
        if(mathAbs(a-currentX)>1||mathAbs(b-currentY)>1){
            tooltipTick=function(){
                move(a,b)
                }
            }else{
        tooltipTick=null
        }
    }
function hide(){
    tooltipIsHidden=true;
    e.hide()
    }
    function refresh(a){
    var b=a.series,borderColor=c.borderColor||a.color||b.color||'#606060',x,y,boxX,boxY,show,bBox,text=a.tooltipText,tooltipPos=a.tooltipPos;
    d=b;
    x=mathRound(tooltipPos?tooltipPos[0]:(inverted?plotWidth-a.plotY:a.plotX));
    y=mathRound(tooltipPos?tooltipPos[1]:(inverted?plotHeight-a.plotX:a.plotY));
    show=isInsidePlot(x,y);
    if(text===false||!show){
        hide()
        }else{
        if(tooltipIsHidden){
            e.show();
            tooltipIsHidden=false
            }
            label.attr({
            text:text
        });
        bBox=label.getBBox();
        boxWidth=bBox.width;
        boxHeight=bBox.height;
        box.attr({
            width:boxWidth+2*padding,
            height:boxHeight+2*padding,
            stroke:borderColor
        });
        boxX=x-boxWidth+plotLeft-25;
        boxY=y-boxHeight+plotTop+10;
        if(boxX<7){
            boxX=7;
            boxY-=20
            }
            if(boxY<5){
            boxY=5
            }else if(boxY+boxHeight>chartHeight){
            boxY=chartHeight-boxHeight-5
            }
            move(mathRound(boxX-boxOffLeft),mathRound(boxY-boxOffLeft))
        }
    }
return{
    refresh:refresh,
    hide:hide
}
}
function MouseTracker(f,g){
    var h,mouseDownY,hasDragged,selectionMarker,zoomType=p.zoomType,zoomX=/x/.test(zoomType),zoomY=/y/.test(zoomType),zoomHor=zoomX&&!inverted||zoomY&&inverted,zoomVert=zoomY&&!inverted||zoomX&&inverted;
    function normalizeMouseEvent(e){
        e=e||win.event;
        if(!e.target){
            e.target=e.srcElement
            }
            if(e.type!='mousemove'||win.opera){
            position=getPosition(container)
            }
            if(isIE){
            e.chartX=e.x;
            e.chartY=e.y
            }else{
            if(e.layerX===UNDEFINED){
                e.chartX=e.pageX-position.x;
                e.chartY=e.pageY-position.y
                }else{
                e.chartX=e.layerX;
                e.chartY=e.layerY
                }
            }
        return e
    }
    function getMouseCoordinates(e){
    var c={
        xAxis:[],
        yAxis:[]
    };

    each(axes,function(a,i){
        var b=a.translate,isXAxis=a.isXAxis,isHorizontal=inverted?!isXAxis:isXAxis;
        c[isXAxis?'xAxis':'yAxis'].push({
            axis:a,
            value:b(isHorizontal?e.chartX-plotLeft:plotHeight-e.chartY+plotTop,true)
            })
        });
    return c
    }
    function onmousemove(e){
    var a,hoverPoint=f.hoverPoint,hoverSeries=f.hoverSeries;
    if(hoverSeries&&hoverSeries.tracker){
        a=hoverSeries.tooltipPoints[inverted?e.chartY:e.chartX-plotLeft];
        if(a&&a!=hoverPoint){
            a.onMouseOver()
            }
        }
}
function resetTracker(){
    var a=f.hoverSeries,hoverPoint=f.hoverPoint;
    if(hoverPoint){
        hoverPoint.onMouseOut()
        }
        if(a){
        a.onMouseOut()
        }
        if(tooltip){
        tooltip.hide()
        }
    }
function drop(){
    if(selectionMarker){
        var c={
            xAxis:[],
            yAxis:[]
        },selectionBox=selectionMarker.getBBox(),selectionLeft=selectionBox.x-plotLeft,selectionTop=selectionBox.y-plotTop;
        if(hasDragged){
            each(axes,function(a,i){
                var b=a.translate,isXAxis=a.isXAxis,isHorizontal=inverted?!isXAxis:isXAxis,selectionMin=b(isHorizontal?selectionLeft:plotHeight-selectionTop-selectionBox.height,true),selectionMax=b(isHorizontal?selectionLeft+selectionBox.width:plotHeight-selectionTop,true);
                c[isXAxis?'xAxis':'yAxis'].push({
                    axis:a,
                    min:mathMin(selectionMin,selectionMax),
                    max:mathMax(selectionMin,selectionMax)
                    })
                });
            fireEvent(f,'selection',c,zoom)
            }
            selectionMarker=selectionMarker.destroy()
        }
        f.mouseIsDown=mouseIsDown=hasDragged=false
    }
    function setDOMEvents(){
    var d=true;
    container.onmousedown=function(e){
        e=normalizeMouseEvent(e);
        if(e.preventDefault){
            e.preventDefault()
            }
            f.mouseIsDown=mouseIsDown=true;
        h=e.chartX;
        mouseDownY=e.chartY;
        if(hasCartesianSeries&&(zoomX||zoomY)){
            if(!selectionMarker){
                selectionMarker=renderer.rect(plotLeft,plotTop,zoomHor?1:plotWidth,zoomVert?1:plotHeight,0).attr({
                    fill:'rgba(69,114,167,0.25)',
                    zIndex:7
                }).add()
                }
            }
    };

container.onmousemove=function(e){
    e=normalizeMouseEvent(e);
    e.returnValue=false;
    var a=e.chartX,chartY=e.chartY,isOutsidePlot=!isInsidePlot(a-plotLeft,chartY-plotTop);
    if(mouseIsDown){
        hasDragged=Math.sqrt(Math.pow(h-a,2)+Math.pow(mouseDownY-chartY,2))>10;
        if(zoomHor){
            var b=a-h;
            selectionMarker.attr({
                width:mathAbs(b),
                x:(b>0?0:b)+h
                })
            }
            if(zoomVert){
            var c=chartY-mouseDownY;
            selectionMarker.attr({
                height:mathAbs(c),
                y:(c>0?0:c)+mouseDownY
                })
            }
        }else if(!isOutsidePlot){
    onmousemove(e)
    }
    if(isOutsidePlot&&!d){
    resetTracker();
    drop()
    }
    d=isOutsidePlot;
return false
};

container.onmouseup=function(e){
    drop()
    };

container.onclick=function(e){
    var a=f.hoverPoint;
    e=normalizeMouseEvent(e);
    e.cancelBubble=true;
    if(!hasDragged){
        if(a&&attr(e.target,'isTracker')){
            var b=a.plotX,plotY=a.plotY;
            extend(a,{
                pageX:position.x+plotLeft+(inverted?plotWidth-plotY:b),
                pageY:position.y+plotTop+(inverted?plotHeight-b:plotY)
                });
            fireEvent(f.hoverSeries||a.series,'click',extend(e,{
                point:a
            }));
            a.firePointEvent('click',e)
            }else{
            extend(e,getMouseCoordinates(e));
            if(isInsidePlot(e.chartX-plotLeft,e.chartY-plotTop)){
                fireEvent(f,'click',e)
                }
            }
    }
hasDragged=false
}
}
function createTrackerGroup(){
    f.trackerGroup=trackerGroup=renderer.g('tracker');
    if(inverted){
        trackerGroup.attr({
            width:f.plotWidth,
            height:f.plotHeight
            }).invert()
        }
        trackerGroup.attr({
        zIndex:9
    }).translate(plotLeft,plotTop).add()
    }
    createTrackerGroup();
if(g.enabled){
    f.tooltip=tooltip=Tooltip(g)
    }
    setDOMEvents();
tooltipInterval=setInterval(function(){
    if(tooltipTick){
        tooltipTick()
        }
    },32);
extend(this,{
    zoomX:zoomX,
    zoomY:zoomY,
    resetTracker:resetTracker
})
}
var q=function(e){
    var f=e.options.legend;
    if(!f.enabled){
        return
    }
    var g=f.layout=='horizontal',symbolWidth=f.symbolWidth,symbolPadding=f.symbolPadding,allItems=[],style=f.style,itemStyle=f.itemStyle,itemHoverStyle=f.itemHoverStyle,itemHiddenStyle=f.itemHiddenStyle,padding=parseInt(style.padding,10),rightPadding=20,lineHeight=f.lineHeight||16,y=18,initialItemX=4+padding+symbolWidth+symbolPadding,itemX,itemY,lastItemY,box,legendBorderWidth=f.borderWidth,legendBackgroundColor=f.backgroundColor,legendGroup,offsetWidth,widthOption=f.width,boxWidth,boxHeight,series=e.series,reversedLegend=f.reversed;
    function colorizeItem(a,b){
        var c=a.legendItem,legendLine=a.legendLine,legendSymbol=a.legendSymbol,hiddenColor=itemHiddenStyle.color,textColor=b?f.itemStyle.color:hiddenColor,symbolColor=b?a.color:hiddenColor;
        if(c){
            c.css({
                color:textColor
            })
            }
            if(legendLine){
            legendLine.attr({
                stroke:symbolColor
            })
            }
            if(legendSymbol){
            legendSymbol.attr({
                stroke:symbolColor,
                fill:symbolColor
            })
            }
        }
    function positionItem(a,b,c){
    var d=a.legendItem,legendLine=a.legendLine,legendSymbol=a.legendSymbol,checkbox=a.checkbox;
    if(d){
        d.attr({
            x:b,
            y:c
        })
        }
        if(legendLine){
        legendLine.translate(b,c-4)
        }
        if(legendSymbol){
        legendSymbol.translate(b,c)
        }
        if(checkbox){
        checkbox.x=b;
        checkbox.y=c
        }
    }
function destroyItem(b){
    var i=allItems.length,checkbox=b.checkbox;
    while(i--){
        if(allItems[i]==b){
            allItems.splice(i,1);
            break
        }
    }
    each(['legendItem','legendLine','legendSymbol'],function(a){
    if(b[a]){
        b[a].destroy()
        }
    });
if(checkbox){
    discardElement(b.checkbox)
    }
}
function renderItem(c){
    var d,itemWidth,legendSymbol,simpleSymbol,li=c.legendItem,series=c.series||c;
    if(!li){
        simpleSymbol=/^(bar|pie|area|column)$/.test(series.type);
        c.legendItem=li=renderer.text(f.labelFormatter.call(c),0,0).css(c.visible?itemStyle:itemHiddenStyle).on('mouseover',function(){
            c.setState(HOVER_STATE);
            li.css(itemHoverStyle)
            }).on('mouseout',function(){
            li.css(c.visible?itemStyle:itemHiddenStyle);
            c.setState()
            }).on('click',function(a){
            var b='legendItemClick',fnLegendItemClick=function(){
                c.setVisible()
                };

            if(c.firePointEvent){
                c.firePointEvent(b,null,fnLegendItemClick)
                }else{
                fireEvent(c,b,null,fnLegendItemClick)
                }
            }).attr({
        zIndex:2
    }).add(legendGroup);
    if(!simpleSymbol&&c.options&&c.options.lineWidth){
        c.legendLine=renderer.path([M,-symbolWidth-symbolPadding,0,L,-symbolPadding,0]).attr({
            'stroke-width':c.options.lineWidth,
            zIndex:2
        }).add(legendGroup)
        }
        if(simpleSymbol){
        legendSymbol=renderer.rect(-symbolWidth-symbolPadding,-11,symbolWidth,12,2).attr({
            'stroke-width':0,
            zIndex:3
        }).add(legendGroup)
        }else if(c.options&&c.options.marker&&c.options.marker.enabled){
        legendSymbol=renderer.symbol(c.symbol,-symbolWidth/2-symbolPadding,-4,c.options.marker.radius).attr(c.pointAttr[NORMAL_STATE]).attr({
            zIndex:3
        }).add(legendGroup)
        }
        c.legendSymbol=legendSymbol;
    colorizeItem(c,c.visible);
    if(c.options&&c.options.showCheckbox){
        c.checkbox=createElement('input',{
            type:'checkbox',
            checked:c.selected,
            defaultChecked:c.selected
            },f.itemCheckboxStyle,container);
        addEvent(c.checkbox,'click',function(a){
            var b=a.target;
            fireEvent(c,'checkboxClick',{
                checked:b.checked
                },function(){
                c.select()
                })
            })
        }
    }
positionItem(c,itemX,itemY);
d=li.getBBox();
lastItemY=itemY;
c.legendItemWidth=itemWidth=f.itemWidth||symbolWidth+symbolPadding+d.width+rightPadding;
if(g){
    itemX+=itemWidth;
    offsetWidth=widthOption||mathMax(itemX-initialItemX,offsetWidth);
    if(itemX-initialItemX+itemWidth>(widthOption||(chartWidth-2*padding-initialItemX))){
        itemX=initialItemX;
        itemY+=lineHeight
        }
    }else{
    itemY+=lineHeight;
    offsetWidth=widthOption||mathMax(itemWidth,offsetWidth)
    }
    allItems.push(c)
}
function renderLegend(){
    itemX=initialItemX;
    itemY=y;
    offsetWidth=0;
    lastItemY=0;
    if(!legendGroup){
        legendGroup=renderer.g('legend').attr({
            zIndex:7
        }).add()
        }
        if(reversedLegend){
        series.reverse()
        }
        each(series,function(a){
        if(!a.options.showInLegend){
            return
        }
        var b=(a.options.legendType=='point')?a.data:[a];
        each(b,renderItem)
        });
    if(reversedLegend){
        series.reverse()
        }
        boxWidth=widthOption||offsetWidth;
    boxHeight=lastItemY-y+lineHeight;
    if(legendBorderWidth||legendBackgroundColor){
        boxWidth+=2*padding;
        boxHeight+=2*padding;
        if(!box){
            box=renderer.rect(0,0,boxWidth,boxHeight,f.borderRadius,legendBorderWidth||0).attr({
                stroke:f.borderColor,
                'stroke-width':legendBorderWidth||0,
                fill:legendBackgroundColor||NONE
                }).add(legendGroup).shadow(f.shadow)
            }else{
            box.attr({
                height:boxHeight,
                width:boxWidth
            })
            }
        }
    var c=['left','right','top','bottom'],prop,i=4;
while(i--){
    prop=c[i];
    if(style[prop]&&style[prop]!='auto'){
        f[i<2?'align':'verticalAlign']=prop;
        f[i<2?'x':'y']=parseInt(style[prop],10)*(i%2?-1:1)
        }
    }
var d=getAlignment(extend({
    width:boxWidth,
    height:boxHeight
},f));
legendGroup.translate(d.x,d.y);
each(allItems,function(a){
    var b=a.checkbox;
    if(b){
        css(b,{
            left:(d.x+a.legendItemWidth+b.x-40)+PX,
            top:(d.y+b.y-11)+PX
            })
        }
    })
}
renderLegend();
return{
    colorizeItem:colorizeItem,
    destroyItem:destroyItem,
    renderLegend:renderLegend
}
};

function initSeries(a){
    var b=a.type||p.defaultSeriesType,typeClass=seriesTypes[b],serie,hasRendered=chart.hasRendered;
    if(hasRendered){
        if(inverted&&b=='column'){
            typeClass=seriesTypes.bar
            }else if(!inverted&&b=='bar'){
            typeClass=seriesTypes.column
            }
        }
    serie=new typeClass();
serie.init(chart,a);
if(!hasRendered&&serie.inverted){
    inverted=true
    }
    if(serie.isCartesian){
    hasCartesianSeries=serie.isCartesian
    }
    series.push(serie);
return serie
}
function addSeries(a,b){
    var c;
    b=pick(b,true);
    fireEvent(chart,'addSeries',{
        options:a
    },function(){
        c=initSeries(a);
        c.isDirty=true;
        chart.isDirty=true;
        if(b){
            chart.redraw()
            }
        });
return c
}
isInsidePlot=function(x,y){
    var a=0,top=0;
    return x>=a&&x<=a+plotWidth&&y>=top&&y<=top+plotHeight
    };

function adjustTickAmounts(){
    if(p.alignTicks!==false){
        each(axes,function(a){
            a.adjustTickAmount()
            })
        }
    }
function redraw(){
    var b=chart.isDirty,hasStackedSeries,seriesLength=series.length,i=seriesLength,serie;
    while(i--){
        serie=series[i];
        if(serie.isDirty&&serie.options.stacking){
            hasStackedSeries=true;
            break
        }
    }
    if(hasStackedSeries){
    i=seriesLength;
    while(i--){
        serie=series[i];
        if(serie.options.stacking){
            serie.isDirty=true
            }
        }
}
each(series,function(a){
    if(a.isDirty){
        a.cleanData();
        a.getSegments();
        if(a.options.legendType=='point'){
            b=true
            }
        }
});
maxTicks=null;
if(hasCartesianSeries){
    each(axes,function(a){
        a.setScale()
        });
    adjustTickAmounts();
    each(axes,function(a){
        if(a.isDirty){
            a.redraw()
            }
        })
}
each(series,function(a){
    if(a.isDirty&&a.visible){
        a.redraw()
        }
    });
if(b&&legend.renderLegend){
    legend.renderLegend();
    chart.isDirty=false
    }
    if(tracker&&tracker.resetTracker){
    tracker.resetTracker()
    }
    fireEvent(chart,'redraw')
}
function showLoading(a){
    var b=n.loading;
    if(!loadingLayer){
        loadingLayer=createElement(DIV,{
            className:'highcharts-loading'
        },extend(b.style,{
            left:plotLeft+PX,
            top:plotTop+PX,
            width:plotWidth+PX,
            height:plotHeight+PX,
            zIndex:10,
            display:NONE
        }),container);
        createElement('span',null,b.labelStyle,loadingLayer)
        }
        if(!loadingShown){
        css(loadingLayer,{
            opacity:0,
            display:''
        });
        loadingLayer.getElementsByTagName('span')[0].innerHTML=a||n.lang.loading;
        animate(loadingLayer,{
            opacity:b.style.opacity
            },{
            duration:b.showDuration
            });
        loadingShown=true
        }
    }
function hideLoading(){
    animate(loadingLayer,{
        opacity:0
    },{
        duration:n.loading.hideDuration,
        complete:function(){
            css(loadingLayer,{
                display:NONE
            })
            }
        });
loadingShown=false
}
function get(a){
    var i,j,data;
    for(i=0;i<axes.length;i++){
        if(axes[i].options.id==a){
            return axes[i]
            }
        }
    for(i=0;i<series.length;i++){
    if(series[i].options.id==a){
        return series[i]
        }
    }
for(i=0;i<series.length;i++){
    data=series[i].data;
    for(j=0;j<data.length;j++){
        if(data[j].id==a){
            return data[j]
            }
        }
    }
return null
}
function getAxes(){
    var b=n.xAxis||{},yAxisOptions=n.yAxis||{},axis;
    b=splat(b);
    each(b,function(a,i){
        a.index=i;
        a.isX=true
        });
    yAxisOptions=splat(yAxisOptions);
    each(yAxisOptions,function(a,i){
        a.index=i
        });
    axes=b.concat(yAxisOptions);
    chart.xAxis=[];
    chart.yAxis=[];
    axes=map(axes,function(a){
        axis=new Axis(chart,a);
        chart[axis.isXAxis?'xAxis':'yAxis'].push(axis);
        return axis
        });
    adjustTickAmounts()
    }
    function getSelectedPoints(){
    var c=[];
    each(series,function(b){
        c=c.concat(grep(b.data,function(a){
            return a.selected
            }))
        });
    return c
    }
    function getSelectedSeries(){
    return grep(series,function(a){
        return a.selected
        })
    }
    zoomOut=function(){
    fireEvent(chart,'selection',{
        resetSelection:true
    },zoom);
    chart.toolbar.remove('zoom')
    };

zoom=function(c){
    var d=defaultOptions.lang;
    chart.toolbar.add('zoom',d.resetZoom,d.resetZoomTitle,zoomOut);
    if(!c||c.resetSelection){
        each(axes,function(a){
            a.setExtremes(null,null,false)
            })
        }else{
        each(c.xAxis.concat(c.yAxis),function(a){
            var b=a.axis;
            if(chart.tracker[b.isXAxis?'zoomX':'zoomY']){
                b.setExtremes(a.min,a.max,false)
                }
            })
    }
    redraw()
};

function showTitle(){
    var a=n.title,titleAlign=a.align,subtitle=n.subtitle,subtitleAlign=subtitle.align,anchorMap={
        left:0,
        center:chartWidth/2,
        right:chartWidth
    };

    if(a&&a.text){
        renderer.text(a.text,anchorMap[titleAlign]+a.x,a.y,a.style,0,titleAlign).attr({
            'class':'highcharts-title'
        }).add()
        }
        if(subtitle&&subtitle.text){
        renderer.text(subtitle.text,anchorMap[subtitleAlign]+subtitle.x,subtitle.y,subtitle.style,0,subtitleAlign).attr({
            'class':'highcharts-subtitle'
        }).add()
        }
    }
getAlignment=function(a){
    var b=a.align,vAlign=a.verticalAlign,optionsX=a.x||0,optionsY=a.y||0,ret={
        x:optionsX||0,
        y:optionsY||0
        };

    if(/^(right|center)$/.test(b)){
        ret.x=(chartWidth-a.width)/{
            right:1,
            center:2
        }
        [b]+optionsX
        }
        if(/^(bottom|middle)$/.test(vAlign)){
        ret.y=(chartHeight-a.height)/{
            bottom:1,
            middle:2
        }
        [vAlign]+optionsY
        }
        return ret
    };

function getContainer(){
    renderTo=p.renderTo;
    containerId=PREFIX+idCounter++;
    if(typeof renderTo=='string'){
        renderTo=u.getElementById(renderTo)
        }
        renderTo.innerHTML='';
    if(!renderTo.offsetWidth){
        renderToClone=renderTo.cloneNode(0);
        css(renderToClone,{
            position:ABSOLUTE,
            top:'-9999px',
            display:''
        });
        u.body.appendChild(renderToClone)
        }
        var a=(renderToClone||renderTo).offsetHeight;
    chart.chartWidth=chartWidth=p.width||(renderToClone||renderTo).offsetWidth||600;
    chart.chartHeight=chartHeight=p.height||(a>plotTop+marginBottom?a:0)||400;
    chart.plotWidth=plotWidth=chartWidth-plotLeft-marginRight;
    chart.plotHeight=plotHeight=chartHeight-plotTop-marginBottom;
    chart.plotLeft=plotLeft;
    chart.plotTop=plotTop;
    chart.container=container=createElement(DIV,{
        className:'highcharts-container'+(p.className?' '+p.className:''),
        id:containerId
    },extend({
        position:RELATIVE,
        overflow:HIDDEN,
        width:chartWidth+PX,
        height:chartHeight+PX,
        textAlign:'left'
    },p.style),renderToClone||renderTo);
    chart.renderer=renderer=p.renderer=='SVG'?new D(container,chartWidth,chartHeight):new G(container,chartWidth,chartHeight)
    }
    function render(){
    var b,labels=n.labels,credits=n.credits,chartBorderWidth=p.borderWidth||0,chartBackgroundColor=p.backgroundColor,plotBackgroundColor=p.plotBackgroundColor,plotBackgroundImage=p.plotBackgroundImage;
    b=2*chartBorderWidth+(p.shadow?8:0);
    if(chartBorderWidth||chartBackgroundColor){
        renderer.rect(b/2,b/2,chartWidth-b,chartHeight-b,p.borderRadius,chartBorderWidth).attr({
            stroke:p.borderColor,
            'stroke-width':chartBorderWidth,
            fill:chartBackgroundColor||NONE
            }).add().shadow(p.shadow)
        }
        if(plotBackgroundColor){
        renderer.rect(plotLeft,plotTop,plotWidth,plotHeight,0).attr({
            fill:plotBackgroundColor
        }).add().shadow(p.plotShadow)
        }
        if(plotBackgroundImage){
        renderer.image(plotBackgroundImage,plotLeft,plotTop,plotWidth,plotHeight).add()
        }
        if(p.plotBorderWidth){
        renderer.rect(plotLeft,plotTop,plotWidth,plotHeight,0,p.plotBorderWidth).attr({
            stroke:p.plotBorderColor,
            'stroke-width':p.plotBorderWidth,
            zIndex:4
        }).add()
        }
        if(hasCartesianSeries){
        each(axes,function(a){
            a.render()
            })
        }
        showTitle();
    if(labels.items){
        each(labels.items,function(){
            var a=extend(labels.style,this.style),x=parseInt(a.left,10)+plotLeft,y=parseInt(a.top,10)+plotTop+12;
            delete a.left;
            delete a.top;
            renderer.text(this.html,x,y,a).attr({
                zIndex:2
            }).add()
            })
        }
        each(series,function(a){
        a.render()
        });
    legend=chart.legend=new q(chart);
    if(!chart.toolbar){
        chart.toolbar=Toolbar(chart)
        }
        if(credits.enabled&&!chart.credits){
        renderer.text(credits.text,chartWidth-10,chartHeight-5,credits.style,0,'right').on('click',function(){
            location.href=credits.href
            }).attr({
            zIndex:8
        }).add()
        }
        chart.hasRendered=true;
    if(renderToClone){
        renderTo.appendChild(container);
        discardElement(renderToClone)
        }
    }
function destroy(){
    var i=series.length;
    removeEvent(win,'unload',destroy);
    removeEvent(chart);
    each(axes,function(a){
        removeEvent(a)
        });
    while(i--){
        series[i].destroy()
        }
        container.onmousedown=container.onmousemove=container.onmouseup=container.onclick=null;
    container.parentNode.removeChild(container);
    container=null;
    clearInterval(tooltipInterval);
    for(i in chart){
        delete chart[i]
    }
    }
    function firstRender(){
    var b='onreadystatechange';
    if(!hasSVG&&u.readyState!='complete'){
        u.attachEvent(b,function(){
            u.detachEvent(b,arguments.callee);
            firstRender()
            });
        return
    }
    getContainer();
    each(n.series||[],function(a){
        initSeries(a)
        });
    chart.inverted=inverted=pick(inverted,n.chart.inverted);
    chart.plotSizeX=plotSizeX=inverted?plotHeight:plotWidth;
    chart.plotSizeY=plotSizeY=inverted?plotWidth:plotHeight;
    chart.tracker=tracker=new MouseTracker(chart,n.tooltip);
    getAxes();
    each(series,function(a){
        a.translate();
        a.setTooltipPoints()
        });
    chart.render=render;
    render();
    fireEvent(chart,'load');
    o&&o(chart)
    }
    colorCounter=0;
symbolCounter=0;
addEvent(win,'unload',destroy);
if(chartEvents){
    for(eventType in chartEvents){
        addEvent(chart,eventType,chartEvents[eventType])
        }
    }
    chart.options=n;
chart.series=series;
chart.addSeries=addSeries;
chart.destroy=destroy;
chart.get=get;
chart.getAlignment=getAlignment;
chart.getSelectedPoints=getSelectedPoints;
chart.getSelectedSeries=getSelectedSeries;
chart.hideLoading=hideLoading;
chart.isInsidePlot=isInsidePlot;
chart.redraw=redraw;
chart.showLoading=showLoading;
firstRender()
}
var H=function(){};

H.prototype={
    init:function(a,b){
        var c=this,defaultColors;
        c.series=a;
        c.applyOptions(b);
        c.pointAttr={};

        if(a.options.colorByPoint){
            defaultColors=a.chart.options.colors;
            if(!c.options){
                c.options={}
            }
            c.color=c.options.color=c.color||defaultColors[colorCounter++];
        if(colorCounter>=defaultColors.length){
            colorCounter=0
            }
        }
    return c
},
applyOptions:function(a){
    var b=this,series=b.series;
    b.config=a;
    if(typeof a=='number'||a===null){
        b.y=a
        }else if(typeof a=='object'&&typeof a.length!='number'){
        extend(b,a);
        b.options=a
        }else if(typeof a[0]=='string'){
        b.name=a[0];
        b.y=a[1]
        }else if(typeof a[0]=='number'){
        b.x=a[0];
        b.y=a[1]
        }
        if(b.x===UNDEFINED){
        b.x=series.autoIncrement()
        }
    },
destroy:function(){
    var b=this,prop;
    if(b==b.series.chart.hoverPoint){
        b.onMouseOut()
        }
        removeEvent(b);
    each(['dataLabel','graphic','tracker','group'],function(a){
        if(b[a]){
            b[a].destroy()
            }
        });
if(b.legendItem){
    b.series.chart.legend.destroyItem(b)
    }
    for(prop in b){
    b[prop]=null
    }
},
select:function(b,c){
    var d=this,series=d.series,chart=series.chart;
    d.selected=b=pick(b,!d.selected);
    d.firePointEvent(b?'select':'unselect');
    d.setState(b&&SELECT_STATE);
    if(!c){
        each(chart.getSelectedPoints(),function(a){
            if(a.selected&&a!=d){
                a.selected=false;
                a.setState(NORMAL_STATE);
                a.firePointEvent('unselect')
                }
            })
    }
},
onMouseOver:function(){
    var a=this,chart=a.series.chart,tooltip=chart.tooltip,hoverPoint=chart.hoverPoint;
    if(hoverPoint&&hoverPoint!=a){
        hoverPoint.onMouseOut()
        }
        a.firePointEvent('mouseOver');
    if(tooltip){
        tooltip.refresh(a)
        }
        a.setState(HOVER_STATE);
    chart.hoverPoint=a
    },
onMouseOut:function(){
    var a=this;
    a.firePointEvent('mouseOut');
    a.setState(NORMAL_STATE);
    a.series.chart.hoverPoint=null
    },
update:function(a,b){
    var c=this,series=c.series;
    b=pick(b,true);
    c.firePointEvent('update',{
        options:a
    },function(){
        c.applyOptions(a);
        series.isDirty=true;
        if(b){
            series.chart.redraw()
            }
        })
},
remove:function(a){
    var b=this,series=b.series,chart=series.chart,data=series.data,i=data.length;
    a=pick(a,true);
    b.firePointEvent('remove',null,function(){
        while(i--){
            if(data[i]==b){
                data.splice(i,1);
                break
            }
        }
        b.destroy();
        series.isDirty=true;
        if(a){
        chart.redraw()
        }
    })
},
firePointEvent:function(b,c,d){
    var e=this,series=this.series,seriesOptions=series.options;
    if(seriesOptions.point.events[b]||(e.options&&e.options.events&&e.options.events[b])){
        this.importEvents()
        }
        if(b=='click'&&seriesOptions.allowPointSelect){
        d=function(a){
            e.select(null,a.ctrlKey||a.metaKey||a.shiftKey)
            }
        }
    fireEvent(this,b,c,d)
},
importEvents:function(){
    if(!this.hasImportedEvents){
        var a=this,options=merge(a.series.options.point,a.options),events=options.events,eventType;
        a.events=events;
        for(eventType in events){
            addEvent(a,eventType,events[eventType])
            }
            this.hasImportedEvents=true
        }
    },
setState:function(a){
    var b=this,series=b.series,stateOptions=series.options.states,markerOptions=series.options.marker,normalDisabled=markerOptions&&!markerOptions.enabled,markerStateOptions=markerOptions&&markerOptions.states[a],stateDisabled=markerStateOptions&&markerStateOptions.enabled===false,chart=series.chart,pointAttr=b.pointAttr;
    if(!a){
        a=NORMAL_STATE
        }
        if((b.selected&&a!=SELECT_STATE)||(stateOptions[a]&&stateOptions[a].enabled===false)||(a&&(stateDisabled||normalDisabled&&!markerStateOptions.enabled))){
        return
    }
    if(a&&!b.graphic){
        if(!series.stateMarkerGraphic){
            series.stateMarkerGraphic=chart.renderer.circle(0,0,pointAttr[a].r).attr(pointAttr[a]).add(series.group)
            }
            series.stateMarkerGraphic.translate(b.plotX,b.plotY)
        }else if(b.graphic){
        b.graphic.attr(pointAttr[a])
        }
    },
setTooltipText:function(){
    var a=this;
    a.tooltipText=a.series.chart.options.tooltip.formatter.call({
        series:a.series,
        point:a,
        x:a.category,
        y:a.y,
        percentage:a.percentage,
        total:a.total||a.stackTotal
        })
    }
};

var I=function(){};

I.prototype={
    isCartesian:true,
    type:'line',
    pointClass:H,
    pointAttrToOptions:{
        stroke:'lineColor',
        'stroke-width':'lineWidth',
        fill:'fillColor',
        r:'radius'
    },
    init:function(a,b){
        var c=this,eventType,events,index=a.series.length;
        c.chart=a;
        b=c.setOptions(b);
        extend(c,{
            index:index,
            options:b,
            name:b.name||'Series '+(index+1),
            state:NORMAL_STATE,
            pointAttr:{},
            visible:b.visible!==false,
            selected:b.selected===true
            });
        events=b.events;
        for(eventType in events){
            addEvent(c,eventType,events[eventType])
            }
            c.getColor();
        c.getSymbol();
        c.setData(b.data,false)
        },
    autoIncrement:function(){
        var a=this,options=a.options,xIncrement=a.xIncrement;
        xIncrement=pick(xIncrement,options.pointStart,0);
        a.pointInterval=pick(a.pointInterval,options.pointInterval,1);
        a.xIncrement=xIncrement+a.pointInterval;
        return xIncrement
        },
    cleanData:function(){
        var c=this,data=c.data,i;
        data.sort(function(a,b){
            return(a.x-b.x)
            });
        for(i=data.length-1;i>=0;i--){
            if(data[i-1]){
                if(data[i-1].x==data[i].x){
                    data.splice(i-1,1)
                    }
                }
        }
    },
getSegments:function(){
    var b=-1,segments=[],data=this.data;
    each(data,function(a,i){
        if(a.y===null){
            if(i>b+1){
                segments.push(data.slice(b+1,i))
                }
                b=i
            }else if(i==data.length-1){
            segments.push(data.slice(b+1,i+1))
            }
        });
this.segments=segments
},
setOptions:function(a){
    var b=this.chart.options.plotOptions,options=merge(b[this.type],b.series,a);
    return options
    },
getColor:function(){
    var a=this.chart.options.colors;
    this.color=this.options.color||a[colorCounter++]||'#0000ff';
    if(colorCounter>=a.length){
        colorCounter=0
        }
    },
getSymbol:function(){
    var a=this.chart.options.symbols,symbol=this.options.marker.symbol||a[symbolCounter++];
    this.symbol=symbol;
    if(symbolCounter>=a.length){
        symbolCounter=0
        }
    },
addPoint:function(a,b,c){
    var d=this,data=d.data,point=(new d.pointClass()).init(d,a);
    b=pick(b,true);
    data.push(point);
    if(c){
        data[0].remove(false)
        }
        d.isDirty=true;
    if(b){
        d.chart.redraw()
        }
    },
setData:function(b,c){
    var d=this,oldData=d.data,initialColor=d.initialColor,i=oldData&&oldData.length||0;
    d.xIncrement=null;
    if(defined(initialColor)){
        colorCounter=initialColor
        }
        b=map(splat(b||[]),function(a){
        return(new d.pointClass()).init(d,a)
        });
    while(i--){
        oldData[i].destroy()
        }
        d.data=b;
    d.cleanData();
    d.getSegments();
    d.isDirty=true;
    if(pick(c,true)){
        d.chart.redraw()
        }
    },
remove:function(a){
    var b=this,chart=b.chart;
    a=pick(a,true);
    if(!b.isRemoving){
        b.isRemoving=true;
        fireEvent(b,'remove',null,function(){
            b.destroy();
            chart.isDirty=true;
            if(a){
                chart.redraw()
                }
            })
    }
    b.isRemoving=false
},
translate:function(){
    var a=this,chart=a.chart,stacking=a.options.stacking,categories=a.xAxis.categories,yAxis=a.yAxis,stack=yAxis.stacks[a.type],data=a.data,i=data.length;
    while(i--){
        var b=data[i],xValue=b.x,yValue=b.y,yBottom,pointStack,pointStackTotal;
        b.plotX=a.xAxis.translate(xValue);
        if(stacking&&a.visible&&stack[xValue]){
            pointStack=stack[xValue];
            pointStackTotal=pointStack.total;
            pointStack.cum=yBottom=pointStack.cum-yValue;
            yValue=yBottom+yValue;
            if(stacking=='percent'){
                yBottom=pointStackTotal?yBottom*100/pointStackTotal:0;
                yValue=pointStackTotal?yValue*100/pointStackTotal:0
                }
                b.percentage=pointStackTotal?b.y*100/pointStackTotal:0;
            b.stackTotal=pointStackTotal;
            b.yBottom=yAxis.translate(yBottom,0,1)
            }
            if(yValue!==null){
            b.plotY=yAxis.translate(yValue,0,1)
            }
            b.clientX=chart.inverted?chart.plotHeight-b.plotX:b.plotX;
        b.category=categories&&categories[b.x]!==UNDEFINED?categories[b.x]:b.x
        }
    },
setTooltipPoints:function(b){
    var c=this,chart=c.chart,inverted=chart.inverted,data=[],plotSize=(inverted?chart.plotTop:chart.plotLeft)+chart.plotSizeX,low,high,tooltipPoints=[];
    if(b){
        c.tooltipPoints=null
        }
        each(c.segments,function(a){
        data=data.concat(a)
        });
    if(c.xAxis&&c.xAxis.reversed){
        data=data.reverse()
        }
        each(data,function(a,i){
        if(!c.tooltipPoints){
            a.setTooltipText()
            }
            low=data[i-1]?data[i-1].high+1:0;
        high=a.high=data[i+1]?(mathFloor((a.plotX+(data[i+1]?data[i+1].plotX:plotSize))/2)):plotSize;
        while(low<=high){
            tooltipPoints[inverted?plotSize-low++:low++]=a
            }
        });
c.tooltipPoints=tooltipPoints
},
onMouseOver:function(){
    var a=this,chart=a.chart,hoverSeries=chart.hoverSeries,stateMarkerGraphic=a.stateMarkerGraphic;
    if(chart.mouseIsDown){
        return
    }
    if(stateMarkerGraphic){
        stateMarkerGraphic.show()
        }
        if(hoverSeries&&hoverSeries!=a){
        hoverSeries.onMouseOut()
        }
        if(a.options.events.mouseOver){
        fireEvent(a,'mouseOver')
        }
        if(a.tracker){
        a.tracker.toFront()
        }
        a.setState(HOVER_STATE);
    chart.hoverSeries=a
    },
onMouseOut:function(){
    var a=this,options=a.options,chart=a.chart,tooltip=chart.tooltip,hoverPoint=chart.hoverPoint;
    if(hoverPoint){
        hoverPoint.onMouseOut()
        }
        if(a&&options.events.mouseOut){
        fireEvent(a,'mouseOut')
        }
        if(tooltip&&!options.stickyTracking){
        tooltip.hide()
        }
        a.setState();
    chart.hoverSeries=null
    },
animate:function(a){
    var b=this,chart=b.chart,clipRect=b.clipRect;
    if(a){
        if(!clipRect.isAnimating){
            clipRect.attr('width',0);
            clipRect.isAnimating=true
            }
        }else{
    clipRect.animate({
        width:chart.plotSizeX
        },{
        complete:function(){
            clipRect.isAnimating=false
            },
        duration:1000
    });
    this.animate=null
    }
},
drawPoints:function(){
    var a=this,pointAttr,data=a.data,chart=a.chart,plotX,plotY,i,point,radius,graphic;
    if(a.options.marker.enabled){
        i=data.length;
        while(i--){
            point=data[i];
            plotX=point.plotX;
            plotY=point.plotY;
            graphic=point.graphic;
            if(plotY!==UNDEFINED){
                pointAttr=point.pointAttr[point.selected?SELECT_STATE:NORMAL_STATE];
                radius=pointAttr.r;
                if(graphic){
                    graphic.attr({
                        x:plotX,
                        y:plotY,
                        r:radius
                    })
                    }else{
                    point.graphic=chart.renderer.symbol(pick(point.marker&&point.marker.symbol,a.symbol),plotX,plotY,radius).attr(pointAttr).add(a.group)
                    }
                }
        }
}
},
convertAttribs:function(a,b,c,d){
    var e=this.pointAttrToOptions,attr,option,obj={};

    a=a||{};

    b=b||{};

    c=c||{};

    d=d||{};

    for(attr in e){
        option=e[attr];
        obj[attr]=pick(a[option],b[attr],c[attr],d[attr])
        }
        return obj
    },
getAttribs:function(){
    var b=this,normalOptions=b.options.marker||b.options,stateOptions=normalOptions.states,stateOptionsHover=stateOptions[HOVER_STATE],pointStateOptionsHover,normalDefaults={},seriesColor=b.color,data=b.data,i,point,seriesPointAttr=[],pointAttr,pointAttrToOptions=b.pointAttrToOptions,hasPointSpecificOptions;
    if(b.options.marker){
        normalDefaults={
            stroke:seriesColor,
            fill:seriesColor
        };

        stateOptionsHover.radius=stateOptionsHover.radius||normalOptions.radius+2;
        stateOptionsHover.lineWidth=stateOptionsHover.lineWidth||normalOptions.lineWidth+1
        }else{
        normalDefaults={
            fill:seriesColor
        };

        stateOptionsHover.color=stateOptionsHover.color||C(stateOptionsHover.color||seriesColor).brighten(stateOptionsHover.brightness).get()
        }
        seriesPointAttr[NORMAL_STATE]=b.convertAttribs(normalOptions,normalDefaults);
    each([HOVER_STATE,SELECT_STATE],function(a){
        seriesPointAttr[a]=b.convertAttribs(stateOptions[a],seriesPointAttr[NORMAL_STATE])
        });
    b.pointAttr=seriesPointAttr;
    i=data.length;
    while(i--){
        point=data[i];
        normalOptions=(point.options&&point.options.marker)||point.options;
        if(normalOptions&&normalOptions.enabled===false){
            normalOptions.radius=0
            }
            hasPointSpecificOptions=false;
        if(point.options){
            for(var c in pointAttrToOptions){
                if(defined(normalOptions[pointAttrToOptions[c]])){
                    hasPointSpecificOptions=true
                    }
                }
            }
            if(hasPointSpecificOptions){
    pointAttr=[];
    stateOptions=normalOptions.states||{};

    pointStateOptionsHover=stateOptions[HOVER_STATE]=stateOptions[HOVER_STATE]||{};

    if(!b.options.marker){
        pointStateOptionsHover.color=C(pointStateOptionsHover.color||point.options.color).brighten(pointStateOptionsHover.brightness||stateOptionsHover.brightness).get()
        }
        pointAttr[NORMAL_STATE]=b.convertAttribs(normalOptions,seriesPointAttr[NORMAL_STATE]);
    pointAttr[HOVER_STATE]=b.convertAttribs(stateOptions[HOVER_STATE],seriesPointAttr[HOVER_STATE],pointAttr[NORMAL_STATE]);
    pointAttr[SELECT_STATE]=b.convertAttribs(stateOptions[SELECT_STATE],seriesPointAttr[SELECT_STATE],pointAttr[NORMAL_STATE])
    }else{
    pointAttr=seriesPointAttr
    }
    point.pointAttr=pointAttr
}
},
destroy:function(){
    var b=this,chart=b.chart,chartSeries=chart.series,clipRect=b.clipRect,prop;
    removeEvent(b);
    if(b.legendItem){
        b.chart.legend.destroyItem(b)
        }
        each(b.data,function(a){
        a.destroy()
        });
    each(['area','graph','dataLabelsGroup','group','tracker'],function(a){
        if(b[a]){
            b[a].destroy()
            }
        });
if(clipRect&&clipRect!=b.chart.clipRect){
    clipRect.destroy()
    }
    if(chart.hoverSeries==b){
    chart.hoverSeries=null
    }
    each(chartSeries,function(a,i){
    if(a==b){
        chartSeries.splice(i,1)
        }
    });
for(prop in b){
    delete b[prop]
}
},
drawDataLabels:function(){
    if(this.options.dataLabels.enabled){
        var c=this,x,y,data=c.data,options=c.options.dataLabels,str,dataLabelsGroup=c.dataLabelsGroup,chart=c.chart,inverted=chart.inverted,seriesType=c.type,color,align;
        if(!dataLabelsGroup){
            dataLabelsGroup=c.dataLabelsGroup=chart.renderer.g(PREFIX+'data-labels').attr({
                visibility:c.visible?VISIBLE:HIDDEN,
                zIndex:4
            }).translate(chart.plotLeft,chart.plotTop).add()
            }
            color=options.color;
        if(color=='auto'){
            color=null
            }
            options.style.color=pick(color,c.color);
        each(data,function(a){
            var b=pick(a.barX,a.plotX),plotY=a.plotY,tooltipPos=a.tooltipPos,pointLabel=a.dataLabel;
            if(pointLabel){
                a.dataLabel=pointLabel.destroy()
                }
                str=options.formatter.call({
                x:a.x,
                y:a.y,
                series:c,
                point:a,
                percentage:a.percentage,
                total:a.total||a.stackTotal
                });
            x=(inverted?chart.plotWidth-plotY:b)+options.x;
            y=(inverted?chart.plotHeight-b:plotY)+options.y;
            if(tooltipPos){
                x=tooltipPos[0]+options.x;
                y=tooltipPos[1]+options.y
                }
                align=options.align;
            if(seriesType=='column'){
                x+={
                    center:a.barW/2,
                    right:a.barW
                    }
                    [align]||0
                }
                if(str){
                a.dataLabel=chart.renderer.text(str,x,y,options.style,options.rotation,align).attr({
                    zIndex:1,
                    visibility:a.visible===false?HIDDEN:'inherit'
                    }).add(dataLabelsGroup)
                }
                if(c.drawConnector){
                c.drawConnector(a)
                }
            })
    }
},
drawGraph:function(e){
    var f=this,options=f.options,chart=f.chart,graph=f.graph,graphPath=[],fillColor,area=f.area,group=f.group,color=options.lineColor||f.color,lineWidth=options.lineWidth,segmentPath,renderer=chart.renderer,translatedThreshold=f.yAxis.getThreshold(options.threshold||0,!f.chart.options.FCconf.negative&&f.yAxis.options.PCreversed),useArea=/^area/.test(f.type),singlePoints=[],areaPath=[];
    each(f.segments,function(c){
        if(c.length>1){
            segmentPath=[];
            each(c,function(a,i){
                if(i<2){
                    segmentPath.push([M,L][i])
                    }
                    if(i&&options.step){
                    var b=c[i-1];
                    segmentPath.push(a.plotX,b.plotY)
                    }
                    segmentPath.push(a.plotX,a.plotY)
                });
            graphPath=graphPath.concat(segmentPath);
            if(useArea){
                var d=[],i,segLength=segmentPath.length;
                for(i=0;i<segLength;i++){
                    d.push(segmentPath[i])
                    }
                    if(options.stacking&&f.type!='areaspline'){
                    for(i=c.length-1;i>=0;i--){
                        d.push(c[i].plotX,c[i].yBottom)
                        }
                    }else{
                d.push(c[c.length-1].plotX,translatedThreshold,c[0].plotX,translatedThreshold,'z')
                }
                areaPath=areaPath.concat(d)
            }
        }else{
        singlePoints.push(c[0])
        }
    });
f.graphPath=graphPath;
f.singlePoints=singlePoints;
if(useArea){
    fillColor=pick(options.fillColor,C(f.color).setOpacity(options.fillOpacity||0.75).get());
    if(area){
        area.attr({
            d:areaPath
        })
        }else{
        f.area=f.chart.renderer.path(areaPath).attr({
            fill:fillColor
        }).add(f.group)
        }
    }
if(graph){
    graph.attr({
        d:graphPath
    })
    }else{
    if(lineWidth){
        f.graph=renderer.path(graphPath).attr({
            'stroke':color,
            'stroke-width':lineWidth+PX
            }).add(group).shadow(options.shadow)
        }
    }
},
render:function(){
    var a=this,chart=a.chart,group,doAnimation=a.options.animation&&a.animate,renderer=chart.renderer;
    if(!a.clipRect){
        a.clipRect=!chart.hasRendered&&chart.clipRect?chart.clipRect:renderer.clipRect(0,0,chart.plotSizeX,chart.plotSizeY);
        if(!chart.clipRect){
            chart.clipRect=a.clipRect
            }
        }
    if(!a.group){
    group=a.group=renderer.g('series');
    if(chart.inverted){
        group.attr({
            width:chart.plotWidth,
            height:chart.plotHeight
            }).invert()
        }
        group.clip(a.clipRect).attr({
        visibility:a.visible?VISIBLE:HIDDEN,
        zIndex:3
    }).translate(chart.plotLeft,chart.plotTop).add()
    }
    a.drawDataLabels();
if(doAnimation){
    a.animate(true)
    }
    a.getAttribs();
if(a.drawGraph){
    a.drawGraph()
    }
    a.drawPoints();
if(a.options.enableMouseTracking!==false){
    a.drawTracker()
    }
    if(doAnimation){
    a.animate()
    }
    a.isDirty=false
},
redraw:function(){
    var a=this;
    a.translate();
    a.setTooltipPoints(true);
    a.render()
    },
setState:function(a){
    var b=this,options=b.options,graph=b.graph,stateOptions=options.states,stateMarkerGraphic=b.stateMarkerGraphic,lineWidth=options.lineWidth;
    a=a||NORMAL_STATE;
    if(b.state!=a){
        b.state=a;
        if(stateOptions[a]&&stateOptions[a].enabled===false){
            return
        }
        if(a){
            lineWidth=stateOptions[a].lineWidth||lineWidth
            }else if(stateMarkerGraphic){
            stateMarkerGraphic.hide()
            }
            if(graph){
            graph.animate({
                'stroke-width':lineWidth
            },a?0:500)
            }
        }
},
setVisible:function(b,c){
    var d=this,chart=d.chart,legendItem=d.legendItem,seriesGroup=d.group,seriesTracker=d.tracker,dataLabelsGroup=d.dataLabelsGroup,showOrHide,i,data=d.data,point,ignoreHiddenSeries=chart.options.chart.ignoreHiddenSeries,oldVisibility=d.visible;
    d.visible=b=b===UNDEFINED?!oldVisibility:b;
    showOrHide=b?'show':'hide';
    if(b){
        d.isDirty=ignoreHiddenSeries
        }
        if(seriesGroup){
        seriesGroup[showOrHide]()
        }
        if(seriesTracker){
        seriesTracker[showOrHide]()
        }else{
        i=data.length;
        while(i--){
            point=data[i];
            if(point.tracker){
                point.tracker[showOrHide]()
                }
            }
    }
if(dataLabelsGroup){
    dataLabelsGroup[showOrHide]()
    }
    if(legendItem){
    chart.legend.colorizeItem(d,b)
    }
    if(ignoreHiddenSeries){
    if(d.options.stacking){
        each(chart.series,function(a){
            if(a.options.stacking&&a.visible){
                a.isDirty=true
                }
            })
    }
}
if(c!==false){
    chart.redraw()
    }
    fireEvent(d,showOrHide)
},
show:function(){
    this.setVisible(true)
    },
hide:function(){
    this.setVisible(false)
    },
select:function(a){
    var b=this;
    b.selected=a=(a===UNDEFINED)?!b.selected:a;
    if(b.checkbox){
        b.checkbox.checked=a
        }
        fireEvent(b,a?'select':'unselect')
    },
drawTracker:function(){
    var a=this,options=a.options,trackerPath=a.graphPath,chart=a.chart,snap=chart.options.tooltip.snap,tracker=a.tracker,cursor=options.cursor,css=cursor&&{
        cursor:cursor
    },singlePoints=a.singlePoints,singlePoint,i;
    for(i=0;i<singlePoints.length;i++){
        singlePoint=singlePoints[i];
        trackerPath.push(M,singlePoint.plotX-3,singlePoint.plotY,L,singlePoint.plotX+3,singlePoint.plotY)
        }
        if(tracker){
        tracker.attr({
            d:trackerPath
        })
        }else{
        a.tracker=chart.renderer.path(trackerPath).attr({
            isTracker:true,
            stroke:TRACKER_FILL,
            fill:NONE,
            'stroke-width':options.lineWidth+2*snap,
            'stroke-linecap':'round',
            visibility:a.visible?VISIBLE:HIDDEN,
            zIndex:1
        }).on('mouseover',function(){
            if(chart.hoverSeries!=a){
                a.onMouseOver()
                }
            }).on('mouseout',function(){
        if(!options.stickyTracking){
            a.onMouseOut()
            }
        }).css(css).add(chart.trackerGroup)
}
}
};

var J=extendClass(I);
seriesTypes.line=J;
var K=extendClass(I,{
    type:'area'
});
seriesTypes.area=K;
function SplineHelper(a){
    var b=[];
    var c=[];
    var i;
    for(i=0;i<a.length;i++){
        b[i]=a[i].plotX;
        c[i]=a[i].plotY
        }
        this.xdata=b;
    this.ydata=c;
    var e=[];
    this.y2=[];
    var n=c.length;
    this.n=n;
    this.y2[0]=0.0;
    this.y2[n-1]=0.0;
    e[0]=0.0;
    for(i=1;i<n-1;i++){
        var d=(b[i+1]-b[i-1]);
        var s=(b[i]-b[i-1])/d;
        var p=s*this.y2[i-1]+2.0;
        this.y2[i]=(s-1.0)/p;
        e[i]=(c[i+1]-c[i])/(b[i+1]-b[i])-(c[i]-c[i-1])/(b[i]-b[i-1]);
        e[i]=(6.0*e[i]/(b[i+1]-b[i-1])-s*e[i-1])/p
        }
        for(var j=n-2;j>=0;j--){
        this.y2[j]=this.y2[j]*this.y2[j+1]+e[j]
        }
    }
    SplineHelper.prototype={
    get:function(a){
        if(!a){
            a=50
            }
            var n=this.n;
        var b=(this.xdata[n-1]-this.xdata[0])/(a-1);
        var c=[];
        var d=[];
        c[0]=this.xdata[0];
        d[0]=this.ydata[0];
        var e=[{
            plotX:c[0],
            plotY:d[0]
            }];
        for(var j=1;j<a;j++){
            c[j]=c[0]+j*b;
            d[j]=this.interpolate(c[j]);
            e[j]={
                plotX:c[j],
                plotY:d[j]
                }
            }
        return e
    },
interpolate:function(c){
    var d=this.n-1;
    var e=0;
    while(d-e>1){
        var k=(d+e)/2;
        if(this.xdata[mathFloor(k)]>c){
            d=k
            }else{
            e=k
            }
        }
    var f=mathFloor(d),intMin=mathFloor(e);
var h=this.xdata[f]-this.xdata[intMin];
var a=(this.xdata[f]-c)/h;
var b=(c-this.xdata[intMin])/h;
return a*this.ydata[intMin]+b*this.ydata[f]+((a*a*a-a)*this.y2[intMin]+(b*b*b-b)*this.y2[f])*(h*h)/6.0
}
};

var N=extendClass(I,{
    type:'spline',
    drawGraph:function(a){
        var b=this,realSegments=b.segments;
        b.splinedata=b.getSplineData();
        b.segments=b.splinedata;
        I.prototype.drawGraph.apply(b,arguments);
        b.segments=realSegments
        },
    getSplineData:function(){
        var d=this,chart=d.chart,splinedata=[],plotSizeX=chart.plotSizeX,num;
        each(d.segments,function(b){
            if(d.xAxis.reversed){
                b=b.reverse()
                }
                var c=[],nextUp,nextDown;
            each(b,function(a,i){
                nextUp=b[i+2]||b[i+1]||a;
                nextDown=b[i-2]||b[i-1]||a;
                if(nextUp.plotX>=0&&nextDown.plotX<=plotSizeX){
                    c.push(a)
                    }
                });
        if(c.length>1){
            num=mathRound(mathMax(plotSizeX,c[c.length-1].clientX-c[0].clientX)/3)
            }
            splinedata.push(b.length>1?num?(new SplineHelper(c)).get(num):[]:b)
            });
    return splinedata
    }
});
seriesTypes.spline=N;
var O=extendClass(N,{
    type:'areaspline'
});
seriesTypes.areaspline=O;
var P=extendClass(I,{
    type:'column',
    pointAttrToOptions:{
        stroke:'borderColor',
        'stroke-width':'borderWidth',
        fill:'color',
        r:'borderRadius'
    },
    init:function(){
        I.prototype.init.apply(this,arguments);
        var b=this,chart=b.chart;
        if(chart.hasRendered){
            each(chart.series,function(a){
                if(a.type==b.type){
                    a.isDirty=true
                    }
                })
        }
    },
translate:function(){
    var c=this,chart=c.chart,columnCount=0,reversedXAxis=c.xAxis.reversed,categories=c.xAxis.categories,stackedIndex;
    I.prototype.translate.apply(c);
    each(chart.series,function(a){
        if(a.type==c.type){
            if(!a.options.stacking){
                a.columnIndex=columnCount++
            }else{
                if(!defined(stackedIndex)){
                    stackedIndex=columnCount++
                }
                a.columnIndex=stackedIndex
                }
            }
    });
var d=c.options,data=c.data,closestPoints=c.closestPoints,categoryWidth=mathAbs(data[1]?data[closestPoints].plotX-data[closestPoints-1].plotX:chart.plotSizeX/(categories?categories.length:1)),groupPadding=categoryWidth*d.groupPadding,groupWidth=categoryWidth-2*groupPadding,pointOffsetWidth=groupWidth/columnCount,optionPointWidth=d.pointWidth,pointPadding=defined(optionPointWidth)?(pointOffsetWidth-optionPointWidth)/2:pointOffsetWidth*d.pointPadding,pointWidth=pick(optionPointWidth,pointOffsetWidth-2*pointPadding),columnIndex=(reversedXAxis?columnCount-c.columnIndex:c.columnIndex)||0,pointXOffset=pointPadding+(groupPadding+columnIndex*pointOffsetWidth-(categoryWidth/2))*(reversedXAxis?-1:1),translatedThreshold=c.yAxis.getThreshold(d.threshold||0),minPointLength=d.minPointLength;
each(data,function(a){
    var b=pick(a.MX,a.plotX+pointXOffset),barH=mathCeil(mathAbs((a.yBottom||translatedThreshold)-a.plotY)),plotY=a.MY?translatedThreshold-((barH/a.y)*a.MY):a.plotY,barY=mathCeil(mathMin(plotY,translatedThreshold)),barW=pick(a.MWidth,pointWidth),trackerY;
    if(mathAbs(barH)<(minPointLength||5)){
        if(minPointLength){
            barH=minPointLength;
            barY=translatedThreshold-(plotY<=translatedThreshold?minPointLength:0)
            }
            trackerY=barY-3
        }
        if(!c.chart.options.FCconf.negative&&a.series.yAxis.options.PCreversed===true){
        barY=barH;
        barH=a.series.yAxis.getThreshold(0,true)-barY
        }
        extend(a,{
        barX:b,
        barY:barY,
        barW:barW,
        barH:barH
    });
    a.shapeType='rect';
    a.shapeArgs={
        x:b,
        y:barY,
        width:barW,
        height:barH,
        r:d.borderRadius
        };

    a.trackerArgs=defined(trackerY)&&merge(a.shapeArgs,{
        height:6,
        y:trackerY
    })
    })
},
getSymbol:function(){},
drawGraph:function(){},
drawPoints:function(){
    var b=this,options=b.options,renderer=b.chart.renderer,graphic,shapeArgs;
    each(b.data,function(a){
        if(defined(a.plotY)){
            graphic=a.graphic;
            shapeArgs=a.shapeArgs;
            if(graphic){
                graphic.attr(shapeArgs)
                }else{
                a.graphic=renderer[a.shapeType](shapeArgs).attr(a.pointAttr[a.selected?SELECT_STATE:NORMAL_STATE]).add(b.group).shadow(options.shadow)
                }
            }
    })
},
drawTracker:function(){
    var c=this,chart=c.chart,renderer=chart.renderer,shapeArgs,tracker,trackerLabel=+new Date(),cursor=c.options.cursor,css=cursor&&{
        cursor:cursor
    },rel;
    each(c.data,function(b){
        tracker=b.tracker;
        shapeArgs=b.trackerArgs||b.shapeArgs;
        if(tracker){
            tracker.attr(shapeArgs)
            }else{
            b.tracker=renderer[b.shapeType](shapeArgs).attr({
                isTracker:trackerLabel,
                fill:TRACKER_FILL,
                visibility:c.visible?VISIBLE:HIDDEN,
                zIndex:1
            }).on('mouseover',function(a){
                rel=a.relatedTarget||a.fromElement;
                if(chart.hoverSeries!=c&&attr(rel,'isTracker')!=trackerLabel){
                    c.onMouseOver()
                    }
                    b.onMouseOver()
                }).on('mouseout',function(a){
                if(!c.options.stickyTracking){
                    rel=a.relatedTarget||a.toElement;
                    if(attr(rel,'isTracker')!=trackerLabel){
                        c.onMouseOut()
                        }
                    }
            }).css(css).add(chart.trackerGroup)
        }
    })
},
cleanData:function(){
    var a=this,data=a.data,interval,smallestInterval,closestPoints,i;
    I.prototype.cleanData.apply(a);
    for(i=data.length-1;i>=0;i--){
        if(data[i-1]){
            interval=data[i].x-data[i-1].x;
            if(smallestInterval===UNDEFINED||interval<smallestInterval){
                smallestInterval=interval;
                closestPoints=i
                }
            }
    }
    a.closestPoints=closestPoints
},
animate:function(c){
    var d=this,data=d.data;
    if(!c){
        each(data,function(a){
            var b=a.graphic;
            if(b){
                b.attr({
                    height:0,
                    y:d.yAxis.translate(0,0,1)
                    });
                b.animate({
                    height:a.barH,
                    y:a.barY
                    },{
                    duration:1000
                })
                }
            });
    d.animate=null
    }
},
remove:function(){
    var b=this,chart=b.chart;
    if(chart.hasRendered){
        each(chart.series,function(a){
            if(a.type==b.type){
                a.isDirty=true
                }
            })
    }
    I.prototype.remove.apply(b,arguments)
}
});
seriesTypes.column=P;
var Q=extendClass(P,{
    type:'bar',
    init:function(a){
        a.inverted=this.inverted=true;
        P.prototype.init.apply(this,arguments)
        }
    });
seriesTypes.bar=Q;
var R=extendClass(I,{
    type:'scatter',
    translate:function(){
        var b=this;
        I.prototype.translate.apply(b);
        each(b.data,function(a){
            a.shapeType='circle';
            a.shapeArgs={
                x:a.plotX,
                y:a.plotY,
                r:b.chart.options.tooltip.snap
                }
            })
    },
drawTracker:function(){
    var c=this,cursor=c.options.cursor,css=cursor&&{
        cursor:cursor
    },graphic;
    each(c.data,function(b){
        graphic=b.graphic;
        if(graphic){
            graphic.attr({
                isTracker:true
            }).on('mouseover',function(a){
                c.onMouseOver();
                b.onMouseOver()
                }).on('mouseout',function(a){
                if(!c.options.stickyTracking){
                    c.onMouseOut()
                    }
                }).css(css)
        }
    })
},
cleanData:function(){}
});
seriesTypes.scatter=R;
var S=extendClass(H,{
    init:function(){
        H.prototype.init.apply(this,arguments);
        var a=this,toggleSlice;
        extend(a,{
            visible:a.visible!==false,
            name:pick(a.name,'Slice')
            });
        toggleSlice=function(){
            a.slice()
            };

        addEvent(a,'select',toggleSlice);
        addEvent(a,'unselect',toggleSlice);
        return a
        },
    setVisible:function(a){
        var b=this,chart=b.series.chart,method;
        b.visible=a=a===UNDEFINED?!b.visible:a;
        method=a?'show':'hide';
        b.group[method]();
        if(b.tracker){
            b.tracker[method]()
            }
            if(b.dataLabel){
            b.dataLabel[method]()
            }
            if(b.legendItem){
            chart.legend.colorizeItem(b,a)
            }
        },
slice:function(a,b){
    var c=this,series=c.series,chart=series.chart,slicedTranslation=c.slicedTranslation;
    b=pick(b,true);
    a=c.sliced=defined(a)?a:!c.sliced;
    c.group.animate({
        translateX:(a?slicedTranslation[0]:chart.plotLeft),
        translateY:(a?slicedTranslation[1]:chart.plotTop)
        },100)
    }
});
var T=extendClass(I,{
    type:'pie',
    isCartesian:false,
    pointClass:S,
    pointAttrToOptions:{
        stroke:'borderColor',
        'stroke-width':'borderWidth',
        fill:'color'
    },
    getColor:function(){
        this.initialColor=colorCounter
        },
    translate:function(){
        var b=0,series=this,cumulative=-0.25,options=series.options,slicedOffset=options.slicedOffset,positions=options.center,chart=series.chart,plotWidth=chart.plotWidth,plotHeight=chart.plotHeight,start,end,angle,data=series.data,circ=2*math.PI,fraction,smallestSize=mathMin(plotWidth,plotHeight),isPercent;
        positions.push(options.size,options.innerSize||0);
        positions=map(positions,function(a,i){
            isPercent=/%$/.test(a);
            return isPercent?[plotWidth,plotHeight,smallestSize,smallestSize][i]*parseInt(a,10)/100:a
            });
        each(data,function(a){
            b+=a.y
            });
        each(data,function(a){
            fraction=b?a.y/b:0;
            start=cumulative*circ;
            cumulative+=fraction;
            end=cumulative*circ;
            a.shapeType='arc';
            a.shapeArgs={
                x:positions[0],
                y:positions[1],
                r:positions[2]/2,
                innerR:positions[3]/2,
                start:start,
                end:end
            };

            angle=(end+start)/2;
            a.slicedTranslation=map([mathCos(angle)*slicedOffset+chart.plotLeft,mathSin(angle)*slicedOffset+chart.plotTop],mathRound);
            a.tooltipPos=[positions[0]+mathCos(angle)*positions[2]*0.35,positions[1]+mathSin(angle)*positions[2]*0.35];
            a.percentage=fraction*100;
            a.total=b
            });
        this.setTooltipPoints()
        },
    render:function(){
        var a=this;
        a.getAttribs();
        this.drawPoints();
        if(a.options.enableMouseTracking!==false){
            a.drawTracker()
            }
            this.drawDataLabels();
        a.isDirty=false
        },
    drawPoints:function(){
        var b=this,chart=b.chart,renderer=chart.renderer,groupTranslation,graphic,shapeArgs;
        each(b.data,function(a){
            graphic=a.graphic;
            shapeArgs=a.shapeArgs;
            if(!a.group){
                groupTranslation=a.sliced?a.slicedTranslation:[chart.plotLeft,chart.plotTop];
                a.group=renderer.g('point').attr({
                    zIndex:3
                }).add().translate(groupTranslation[0],groupTranslation[1])
                }
                if(graphic){
                graphic.attr(shapeArgs)
                }else{
                a.graphic=renderer.arc(shapeArgs).attr(a.pointAttr[NORMAL_STATE]).add(a.group)
                }
                if(a.visible===false){
                a.setVisible(false)
                }
            })
    },
drawTracker:P.prototype.drawTracker,
getSymbol:function(){}
});
seriesTypes.pie=T;
win.Highcharts={
    Chart:Chart,
    dateFormat:dateFormat,
    getOptions:getOptions,
    numberFormat:numberFormat,
    Point:H,
    Renderer:G,
    seriesTypes:seriesTypes,
    setOptions:setOptions,
    Series:I,
    addEvent:addEvent,
    createElement:createElement,
    discardElement:discardElement,
    css:css,
    each:each,
    extend:extend,
    map:map,
    merge:merge,
    pick:pick,
    extendClass:extendClass
}
})();
(function(){
    var g=Highcharts,Chart=g.Chart,addEvent=g.addEvent,defaultOptions=g.defaultOptions,createElement=g.createElement,discardElement=g.discardElement,css=g.css,merge=g.merge,each=g.each,extend=g.extend,math=Math,mathMax=math.max,doc=document,win=window,M='M',L='L',DIV='div',HIDDEN='hidden',NONE='none',PREFIX='highcharts-',ABSOLUTE='absolute',PX='px',defaultOptions=g.setOptions({
        lang:{
            downloadPNG:'Download PNG image',
            downloadJPEG:'Download JPEG image',
            downloadPDF:'Download PDF document',
            downloadSVG:'Download SVG vector image',
            exportButtonTitle:'Export to raster or vector image',
            printButtonTitle:'Print the chart'
        }
    });
defaultOptions.navigation={
    menuStyle:{
        border:'1px solid #A0A0A0',
        background:'#FFFFFF'
    },
    menuItemStyle:{
        padding:'0 5px',
        background:NONE,
        color:'#303030'
    },
    menuItemHoverStyle:{
        background:'#4572A5',
        color:'#FFFFFF'
    },
    buttonOptions:{
        align:'right',
        backgroundColor:{
            linearGradient:[0,0,0,20],
            stops:[[0.4,'#F7F7F7'],[0.6,'#E3E3E3']]
            },
        borderColor:'#B0B0B0',
        borderRadius:3,
        borderWidth:1,
        height:20,
        hoverBorderColor:'#909090',
        hoverSymbolFill:'#81A7CF',
        hoverSymbolStroke:'#4572A5',
        symbolFill:'#E0E0E0',
        symbolStroke:'#A0A0A0',
        symbolX:11.5,
        symbolY:10.5,
        verticalAlign:'top',
        width:24,
        y:10
    }
};

defaultOptions.exporting={
    type:'image/png',
    url:'http://export.highcharts.com/',
    width:800,
    buttons:{
        exportButton:{
            symbol:'exportIcon',
            x:-10,
            symbolFill:'#A8BF77',
            hoverSymbolFill:'#768F3E',
            _titleKey:'exportButtonTitle',
            menuItems:[{
                textKey:'downloadPNG',
                onclick:function(){
                    this.exportChart()
                    }
                },{
            textKey:'downloadJPEG',
            onclick:function(){
                this.exportChart({
                    type:'image/jpeg'
                })
                }
            },{
        textKey:'downloadPDF',
        onclick:function(){
            this.exportChart({
                type:'application/pdf'
            })
            }
        },{
    textKey:'downloadSVG',
    onclick:function(){
        this.exportChart({
            type:'image/svg+xml'
        })
        }
    }]
},
printButton:{
    symbol:'printIcon',
    x:-36,
    symbolFill:'#B5C9DF',
    hoverSymbolFill:'#779ABF',
    _titleKey:'printButtonTitle',
    onclick:function(){
        this.print()
        }
    }
}
};

extend(Chart.prototype,{
    getSVG:function(d){
        var e=this,chartCopy,sandbox,svg,seriesOptions,pointOptions,pointMarker,options=merge(e.options,d);
        if(!doc.createElementNS){
            doc.createElementNS=function(a,b){
                var c=doc.createElement(b);
                c.getBBox=function(){
                    return e.renderer.Element.prototype.getBBox.apply({
                        element:c
                    })
                    };

                return c
                }
            }
        sandbox=createElement(DIV,null,{
        position:ABSOLUTE,
        top:'-9999em',
        width:e.chartWidth+PX,
        height:e.chartHeight+PX
        },doc.body);
    extend(options.chart,{
        renderTo:sandbox,
        renderer:'SVG'
    });
    options.exporting.enabled=false;
    options.chart.plotBackgroundImage=null;
    options.series=[];
    each(e.series,function(b){
        seriesOptions=b.options;
        seriesOptions.animation=false;
        seriesOptions.showCheckbox=false;
        seriesOptions.data=[];
        each(b.data,function(a){
            pointOptions=a.config==null||typeof a.config=='number'?{
                y:a.y
                }:a.config;
            pointOptions.x=a.x;
            seriesOptions.data.push(pointOptions);
            pointMarker=a.config&&a.config.marker;
            if(pointMarker&&/^url\(/.test(pointMarker.symbol)){
                delete pointMarker.symbol
                }
            });
    options.series.push(seriesOptions)
        });
chartCopy=new Highcharts.Chart(options);
    svg=chartCopy.container.innerHTML;
    options=null;
    chartCopy.destroy();
    discardElement(sandbox);
    svg=svg.replace(/zIndex="[^"]+"/g,'').replace(/isShadow="[^"]+"/g,'').replace(/symbolName="[^"]+"/g,'').replace(/jQuery[0-9]+="[^"]+"/g,'').replace(/isTracker="[^"]+"/g,'').replace(/url\([^#]+#/g,'url(#').replace(/id=([^" >]+)/g,'id="$1"').replace(/class=([^" ]+)/g,'class="$1"').replace(/ transform /g,' ').replace(/:path/g,'path').replace(/style="([^"]+)"/g,function(s){
    return s.toLowerCase()
    });
svg=svg.replace(/(url\(#highcharts-[0-9]+)&quot;/g,'$1').replace(/&quot;/g,"'");
    if(svg.match(/ xmlns="/g).length==2){
    svg=svg.replace(/xmlns="[^"]+"/,'')
    }
    return svg
},
exportChart:function(b,c){
    var d,chart=this,svg=chart.getSVG(c);
    b=merge(chart.options.exporting,b);
    d=createElement('form',{
        method:'post',
        action:b.url
        },{
        display:NONE
    },doc.body);
    each(['filename','type','width','svg'],function(a){
        createElement('input',{
            type:HIDDEN,
            name:a,
            value:{
                filename:b.filename||'chart',
                type:b.type,
                width:b.width,
                svg:svg
            }
            [a]
            },null,d)
        });
    d.submit();
    discardElement(d)
    },
print:function(){
    var b=this,container=b.container,i,origDisplay=[],origParent=container.parentNode,body=doc.body,childNodes=body.childNodes;
    if(b.isPrinting){
        return
    }
    b.isPrinting=true;
    each(childNodes,function(a,i){
        if(a.nodeType==1){
            origDisplay[i]=a.style.display;
            a.style.display=NONE
            }
        });
body.appendChild(container);
win.print();
setTimeout(function(){
    origParent.appendChild(container);
    each(childNodes,function(a,i){
        if(a.nodeType==1){
            a.style.display=origDisplay[i]
            }
        });
b.isPrinting=false
},1000)
},
contextMenu:function(b,c,x,y,d,e){
    var f=this,navOptions=f.options.navigation,menuItemStyle=navOptions.menuItemStyle,chartWidth=f.chartWidth,chartHeight=f.chartHeight,cacheName='cache-'+b,menu=f[cacheName],menuPadding=mathMax(d,e),boxShadow='3px 3px 10px #888',innerMenu,hide,menuStyle;
    if(!menu){
        f[cacheName]=menu=createElement(DIV,{
            className:PREFIX+b
            },{
            position:ABSOLUTE,
            zIndex:1000,
            padding:menuPadding+PX
            },f.container);
        innerMenu=createElement(DIV,null,extend({
            MozBoxShadow:boxShadow,
            WebkitBoxShadow:boxShadow,
            boxShadow:boxShadow
        },navOptions.menuStyle),menu);
        hide=function(){
            css(menu,{
                display:NONE
            })
            };

        addEvent(menu,'mouseleave',hide);
        each(c,function(a){
            if(a){
                createElement(DIV,{
                    onclick:function(){
                        hide();
                        a.onclick.apply(f,arguments)
                        },
                    onmouseover:function(){
                        css(this,navOptions.menuItemHoverStyle)
                        },
                    onmouseout:function(){
                        css(this,menuItemStyle)
                        },
                    innerHTML:a.text||g.getOptions().lang[a.textKey]
                    },extend({
                    cursor:'pointer'
                },menuItemStyle),innerMenu)
                }
            });
    f.exportMenuWidth=menu.offsetWidth;
    f.exportMenuHeight=menu.offsetHeight
    }
    menuStyle={
    display:'block'
};

if(x+f.exportMenuWidth>chartWidth){
    menuStyle.right=(chartWidth-x-d-menuPadding)+PX
    }else{
    menuStyle.left=(x-menuPadding)+PX
    }
    if(y+e+f.exportMenuHeight>chartHeight){
    menuStyle.bottom=(chartHeight-y-menuPadding)+PX
    }else{
    menuStyle.top=(y+e-menuPadding)+PX
    }
    css(menu,menuStyle)
},
addButton:function(a){
    var b=this,renderer=b.renderer,btnOptions=merge(b.options.navigation.buttonOptions,a),onclick=btnOptions.onclick,menuItems=btnOptions.menuItems,position=b.getAlignment(btnOptions),buttonLeft=position.x,buttonTop=position.y,buttonWidth=btnOptions.width,buttonHeight=btnOptions.height,box,symbol,button,borderWidth=btnOptions.borderWidth,boxAttr={
        stroke:btnOptions.borderColor
        },symbolAttr={
        stroke:btnOptions.symbolStroke,
        fill:btnOptions.symbolFill
        };

    if(btnOptions.enabled===false){
        return
    }
    function revert(){
        symbol.attr(symbolAttr);
        box.attr(boxAttr)
        }
        box=renderer.rect(0,0,buttonWidth,buttonHeight,btnOptions.borderRadius,borderWidth).translate(buttonLeft,buttonTop).attr(extend({
        fill:btnOptions.backgroundColor,
        'stroke-width':borderWidth,
        zIndex:19
    },boxAttr)).add();
    button=renderer.rect(buttonLeft,buttonTop,buttonWidth,buttonHeight,0).attr({
        fill:'rgba(255, 255, 255, 0.001)',
        title:g.getOptions().lang[btnOptions._titleKey],
        zIndex:21
    }).css({
        cursor:'pointer'
    }).on('mouseover',function(){
        symbol.attr({
            stroke:btnOptions.hoverSymbolStroke,
            fill:btnOptions.hoverSymbolFill
            });
        box.attr({
            stroke:btnOptions.hoverBorderColor
            })
        }).on('mouseout',revert).add();
    addEvent(button.element,'click',revert);
    if(menuItems){
        onclick=function(e){
            b.contextMenu('export-menu',menuItems,buttonLeft,buttonTop,buttonWidth,buttonHeight)
            }
        }
    addEvent(button.element,'click',function(){
    onclick.apply(b,arguments)
    });
symbol=renderer.symbol(btnOptions.symbol,buttonLeft+btnOptions.symbolX,buttonTop+btnOptions.symbolY,(btnOptions.symbolSize||12)/2).attr(extend(symbolAttr,{
    'stroke-width':btnOptions.symbolStrokeWidth||1,
    zIndex:20
})).add()
}
});
g.Renderer.prototype.symbols.exportIcon=function(x,y,a){
    return[M,x-a,y+a,L,x+a,y+a,x+a,y+a*0.5,x-a,y+a*0.5,'Z',M,x,y+a*0.5,L,x-a*0.5,y-a/3,x-a/6,y-a/3,x-a/6,y-a,x+a/6,y-a,x+a/6,y-a/3,x+a*0.5,y-a/3,'Z']
    };

g.Renderer.prototype.symbols.printIcon=function(x,y,a){
    return[M,x-a,y+a*0.5,L,x+a,y+a*0.5,x+a,y-a/3,x-a,y-a/3,'Z',M,x-a*0.5,y-a/3,L,x-a*0.5,y-a,x+a*0.5,y-a,x+a*0.5,y-a/3,'Z',M,x-a*0.5,y+a*0.5,L,x-a*0.75,y+a,x+a*0.75,y+a,x+a*0.5,y+a*0.5,'Z']
    };

g.Chart=function(b,c){
    return new Chart(b,function(a){
        var n,exportingOptions=a.options.exporting,buttons=exportingOptions.buttons;
        if(exportingOptions.enabled!==false){
            for(n in buttons){
                a.addButton(buttons[n])
                }
            }
            if(c){
        c()
        }
    })
}
})();