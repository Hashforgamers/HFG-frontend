(function(){const t=document.createElement("link").relList;if(t&&t.supports&&t.supports("modulepreload"))return;for(const i of document.querySelectorAll('link[rel="modulepreload"]'))n(i);new MutationObserver(i=>{for(const s of i)if(s.type==="childList")for(const a of s.addedNodes)a.tagName==="LINK"&&a.rel==="modulepreload"&&n(a)}).observe(document,{childList:!0,subtree:!0});function e(i){const s={};return i.integrity&&(s.integrity=i.integrity),i.referrerPolicy&&(s.referrerPolicy=i.referrerPolicy),i.crossOrigin==="use-credentials"?s.credentials="include":i.crossOrigin==="anonymous"?s.credentials="omit":s.credentials="same-origin",s}function n(i){if(i.ep)return;i.ep=!0;const s=e(i);fetch(i.href,s)}})();/**
 * @license
 * Copyright 2010-2024 Three.js Authors
 * SPDX-License-Identifier: MIT
 */const tl="170",Zu=0,kl=1,Ju=2,Lh=1,Qu=2,Wn=3,Zn=0,$e=1,hn=2,$n=0,mi=1,dn=2,Bl=3,zl=4,td=5,Li=100,ed=101,nd=102,id=103,sd=104,rd=200,ad=201,od=202,ld=203,no=204,io=205,cd=206,hd=207,ud=208,dd=209,fd=210,pd=211,md=212,gd=213,vd=214,so=0,ro=1,ao=2,as=3,oo=4,lo=5,co=6,ho=7,el=0,_d=1,xd=2,gi=0,Ih=1,Dh=2,Nh=3,nl=4,yd=5,Uh=6,Fh=7,Hl="attached",Md="detached",Oh=300,os=301,ls=302,uo=303,fo=304,ia=306,vi=1e3,fi=1001,$r=1002,Xe=1003,kh=1004,Bs=1005,tn=1006,Br=1007,qn=1008,Jn=1009,Bh=1010,zh=1011,Ks=1012,il=1013,Ui=1014,Sn=1015,Pn=1016,sl=1017,rl=1018,cs=1020,Hh=35902,Vh=1021,Gh=1022,un=1023,Wh=1024,Xh=1025,is=1026,hs=1027,al=1028,ol=1029,qh=1030,ll=1031,cl=1033,zr=33776,Hr=33777,Vr=33778,Gr=33779,po=35840,mo=35841,go=35842,vo=35843,_o=36196,xo=37492,yo=37496,Mo=37808,bo=37809,So=37810,wo=37811,To=37812,Eo=37813,Ao=37814,Ro=37815,Co=37816,Po=37817,Lo=37818,Io=37819,Do=37820,No=37821,Wr=36492,Uo=36494,Fo=36495,Yh=36283,Oo=36284,ko=36285,Bo=36286,$s=2300,js=2301,fa=2302,Vl=2400,Gl=2401,Wl=2402,bd=2500,Sd=0,Kh=1,zo=2,wd=3200,Td=3201,hl=0,Ed=1,di="",be="srgb",qe="srgb-linear",sa="linear",se="srgb",ki=7680,Xl=519,Ad=512,Rd=513,Cd=514,$h=515,Pd=516,Ld=517,Id=518,Dd=519,Ho=35044,Yn=35048,ql="300 es",Kn=2e3,jr=2001;class _s{addEventListener(t,e){this._listeners===void 0&&(this._listeners={});const n=this._listeners;n[t]===void 0&&(n[t]=[]),n[t].indexOf(e)===-1&&n[t].push(e)}hasEventListener(t,e){if(this._listeners===void 0)return!1;const n=this._listeners;return n[t]!==void 0&&n[t].indexOf(e)!==-1}removeEventListener(t,e){if(this._listeners===void 0)return;const i=this._listeners[t];if(i!==void 0){const s=i.indexOf(e);s!==-1&&i.splice(s,1)}}dispatchEvent(t){if(this._listeners===void 0)return;const n=this._listeners[t.type];if(n!==void 0){t.target=this;const i=n.slice(0);for(let s=0,a=i.length;s<a;s++)i[s].call(this,t);t.target=null}}}const Oe=["00","01","02","03","04","05","06","07","08","09","0a","0b","0c","0d","0e","0f","10","11","12","13","14","15","16","17","18","19","1a","1b","1c","1d","1e","1f","20","21","22","23","24","25","26","27","28","29","2a","2b","2c","2d","2e","2f","30","31","32","33","34","35","36","37","38","39","3a","3b","3c","3d","3e","3f","40","41","42","43","44","45","46","47","48","49","4a","4b","4c","4d","4e","4f","50","51","52","53","54","55","56","57","58","59","5a","5b","5c","5d","5e","5f","60","61","62","63","64","65","66","67","68","69","6a","6b","6c","6d","6e","6f","70","71","72","73","74","75","76","77","78","79","7a","7b","7c","7d","7e","7f","80","81","82","83","84","85","86","87","88","89","8a","8b","8c","8d","8e","8f","90","91","92","93","94","95","96","97","98","99","9a","9b","9c","9d","9e","9f","a0","a1","a2","a3","a4","a5","a6","a7","a8","a9","aa","ab","ac","ad","ae","af","b0","b1","b2","b3","b4","b5","b6","b7","b8","b9","ba","bb","bc","bd","be","bf","c0","c1","c2","c3","c4","c5","c6","c7","c8","c9","ca","cb","cc","cd","ce","cf","d0","d1","d2","d3","d4","d5","d6","d7","d8","d9","da","db","dc","dd","de","df","e0","e1","e2","e3","e4","e5","e6","e7","e8","e9","ea","eb","ec","ed","ee","ef","f0","f1","f2","f3","f4","f5","f6","f7","f8","f9","fa","fb","fc","fd","fe","ff"];let Yl=1234567;const Vs=Math.PI/180,us=180/Math.PI;function wn(){const r=Math.random()*4294967295|0,t=Math.random()*4294967295|0,e=Math.random()*4294967295|0,n=Math.random()*4294967295|0;return(Oe[r&255]+Oe[r>>8&255]+Oe[r>>16&255]+Oe[r>>24&255]+"-"+Oe[t&255]+Oe[t>>8&255]+"-"+Oe[t>>16&15|64]+Oe[t>>24&255]+"-"+Oe[e&63|128]+Oe[e>>8&255]+"-"+Oe[e>>16&255]+Oe[e>>24&255]+Oe[n&255]+Oe[n>>8&255]+Oe[n>>16&255]+Oe[n>>24&255]).toLowerCase()}function Ae(r,t,e){return Math.max(t,Math.min(e,r))}function ul(r,t){return(r%t+t)%t}function Nd(r,t,e,n,i){return n+(r-t)*(i-n)/(e-t)}function Ud(r,t,e){return r!==t?(e-r)/(t-r):0}function Gs(r,t,e){return(1-e)*r+e*t}function Fd(r,t,e,n){return Gs(r,t,1-Math.exp(-e*n))}function Od(r,t=1){return t-Math.abs(ul(r,t*2)-t)}function kd(r,t,e){return r<=t?0:r>=e?1:(r=(r-t)/(e-t),r*r*(3-2*r))}function Bd(r,t,e){return r<=t?0:r>=e?1:(r=(r-t)/(e-t),r*r*r*(r*(r*6-15)+10))}function zd(r,t){return r+Math.floor(Math.random()*(t-r+1))}function Hd(r,t){return r+Math.random()*(t-r)}function Vd(r){return r*(.5-Math.random())}function Gd(r){r!==void 0&&(Yl=r);let t=Yl+=1831565813;return t=Math.imul(t^t>>>15,t|1),t^=t+Math.imul(t^t>>>7,t|61),((t^t>>>14)>>>0)/4294967296}function Wd(r){return r*Vs}function Xd(r){return r*us}function qd(r){return(r&r-1)===0&&r!==0}function Yd(r){return Math.pow(2,Math.ceil(Math.log(r)/Math.LN2))}function Kd(r){return Math.pow(2,Math.floor(Math.log(r)/Math.LN2))}function $d(r,t,e,n,i){const s=Math.cos,a=Math.sin,o=s(e/2),l=a(e/2),c=s((t+n)/2),h=a((t+n)/2),u=s((t-n)/2),d=a((t-n)/2),f=s((n-t)/2),m=a((n-t)/2);switch(i){case"XYX":r.set(o*h,l*u,l*d,o*c);break;case"YZY":r.set(l*d,o*h,l*u,o*c);break;case"ZXZ":r.set(l*u,l*d,o*h,o*c);break;case"XZX":r.set(o*h,l*m,l*f,o*c);break;case"YXY":r.set(l*f,o*h,l*m,o*c);break;case"ZYZ":r.set(l*m,l*f,o*h,o*c);break;default:console.warn("THREE.MathUtils: .setQuaternionFromProperEuler() encountered an unknown order: "+i)}}function Mn(r,t){switch(t.constructor){case Float32Array:return r;case Uint32Array:return r/4294967295;case Uint16Array:return r/65535;case Uint8Array:return r/255;case Int32Array:return Math.max(r/2147483647,-1);case Int16Array:return Math.max(r/32767,-1);case Int8Array:return Math.max(r/127,-1);default:throw new Error("Invalid component type.")}}function ae(r,t){switch(t.constructor){case Float32Array:return r;case Uint32Array:return Math.round(r*4294967295);case Uint16Array:return Math.round(r*65535);case Uint8Array:return Math.round(r*255);case Int32Array:return Math.round(r*2147483647);case Int16Array:return Math.round(r*32767);case Int8Array:return Math.round(r*127);default:throw new Error("Invalid component type.")}}const jh={DEG2RAD:Vs,RAD2DEG:us,generateUUID:wn,clamp:Ae,euclideanModulo:ul,mapLinear:Nd,inverseLerp:Ud,lerp:Gs,damp:Fd,pingpong:Od,smoothstep:kd,smootherstep:Bd,randInt:zd,randFloat:Hd,randFloatSpread:Vd,seededRandom:Gd,degToRad:Wd,radToDeg:Xd,isPowerOfTwo:qd,ceilPowerOfTwo:Yd,floorPowerOfTwo:Kd,setQuaternionFromProperEuler:$d,normalize:ae,denormalize:Mn};class nt{constructor(t=0,e=0){nt.prototype.isVector2=!0,this.x=t,this.y=e}get width(){return this.x}set width(t){this.x=t}get height(){return this.y}set height(t){this.y=t}set(t,e){return this.x=t,this.y=e,this}setScalar(t){return this.x=t,this.y=t,this}setX(t){return this.x=t,this}setY(t){return this.y=t,this}setComponent(t,e){switch(t){case 0:this.x=e;break;case 1:this.y=e;break;default:throw new Error("index is out of range: "+t)}return this}getComponent(t){switch(t){case 0:return this.x;case 1:return this.y;default:throw new Error("index is out of range: "+t)}}clone(){return new this.constructor(this.x,this.y)}copy(t){return this.x=t.x,this.y=t.y,this}add(t){return this.x+=t.x,this.y+=t.y,this}addScalar(t){return this.x+=t,this.y+=t,this}addVectors(t,e){return this.x=t.x+e.x,this.y=t.y+e.y,this}addScaledVector(t,e){return this.x+=t.x*e,this.y+=t.y*e,this}sub(t){return this.x-=t.x,this.y-=t.y,this}subScalar(t){return this.x-=t,this.y-=t,this}subVectors(t,e){return this.x=t.x-e.x,this.y=t.y-e.y,this}multiply(t){return this.x*=t.x,this.y*=t.y,this}multiplyScalar(t){return this.x*=t,this.y*=t,this}divide(t){return this.x/=t.x,this.y/=t.y,this}divideScalar(t){return this.multiplyScalar(1/t)}applyMatrix3(t){const e=this.x,n=this.y,i=t.elements;return this.x=i[0]*e+i[3]*n+i[6],this.y=i[1]*e+i[4]*n+i[7],this}min(t){return this.x=Math.min(this.x,t.x),this.y=Math.min(this.y,t.y),this}max(t){return this.x=Math.max(this.x,t.x),this.y=Math.max(this.y,t.y),this}clamp(t,e){return this.x=Math.max(t.x,Math.min(e.x,this.x)),this.y=Math.max(t.y,Math.min(e.y,this.y)),this}clampScalar(t,e){return this.x=Math.max(t,Math.min(e,this.x)),this.y=Math.max(t,Math.min(e,this.y)),this}clampLength(t,e){const n=this.length();return this.divideScalar(n||1).multiplyScalar(Math.max(t,Math.min(e,n)))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this}negate(){return this.x=-this.x,this.y=-this.y,this}dot(t){return this.x*t.x+this.y*t.y}cross(t){return this.x*t.y-this.y*t.x}lengthSq(){return this.x*this.x+this.y*this.y}length(){return Math.sqrt(this.x*this.x+this.y*this.y)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)}normalize(){return this.divideScalar(this.length()||1)}angle(){return Math.atan2(-this.y,-this.x)+Math.PI}angleTo(t){const e=Math.sqrt(this.lengthSq()*t.lengthSq());if(e===0)return Math.PI/2;const n=this.dot(t)/e;return Math.acos(Ae(n,-1,1))}distanceTo(t){return Math.sqrt(this.distanceToSquared(t))}distanceToSquared(t){const e=this.x-t.x,n=this.y-t.y;return e*e+n*n}manhattanDistanceTo(t){return Math.abs(this.x-t.x)+Math.abs(this.y-t.y)}setLength(t){return this.normalize().multiplyScalar(t)}lerp(t,e){return this.x+=(t.x-this.x)*e,this.y+=(t.y-this.y)*e,this}lerpVectors(t,e,n){return this.x=t.x+(e.x-t.x)*n,this.y=t.y+(e.y-t.y)*n,this}equals(t){return t.x===this.x&&t.y===this.y}fromArray(t,e=0){return this.x=t[e],this.y=t[e+1],this}toArray(t=[],e=0){return t[e]=this.x,t[e+1]=this.y,t}fromBufferAttribute(t,e){return this.x=t.getX(e),this.y=t.getY(e),this}rotateAround(t,e){const n=Math.cos(e),i=Math.sin(e),s=this.x-t.x,a=this.y-t.y;return this.x=s*n-a*i+t.x,this.y=s*i+a*n+t.y,this}random(){return this.x=Math.random(),this.y=Math.random(),this}*[Symbol.iterator](){yield this.x,yield this.y}}class Ut{constructor(t,e,n,i,s,a,o,l,c){Ut.prototype.isMatrix3=!0,this.elements=[1,0,0,0,1,0,0,0,1],t!==void 0&&this.set(t,e,n,i,s,a,o,l,c)}set(t,e,n,i,s,a,o,l,c){const h=this.elements;return h[0]=t,h[1]=i,h[2]=o,h[3]=e,h[4]=s,h[5]=l,h[6]=n,h[7]=a,h[8]=c,this}identity(){return this.set(1,0,0,0,1,0,0,0,1),this}copy(t){const e=this.elements,n=t.elements;return e[0]=n[0],e[1]=n[1],e[2]=n[2],e[3]=n[3],e[4]=n[4],e[5]=n[5],e[6]=n[6],e[7]=n[7],e[8]=n[8],this}extractBasis(t,e,n){return t.setFromMatrix3Column(this,0),e.setFromMatrix3Column(this,1),n.setFromMatrix3Column(this,2),this}setFromMatrix4(t){const e=t.elements;return this.set(e[0],e[4],e[8],e[1],e[5],e[9],e[2],e[6],e[10]),this}multiply(t){return this.multiplyMatrices(this,t)}premultiply(t){return this.multiplyMatrices(t,this)}multiplyMatrices(t,e){const n=t.elements,i=e.elements,s=this.elements,a=n[0],o=n[3],l=n[6],c=n[1],h=n[4],u=n[7],d=n[2],f=n[5],m=n[8],v=i[0],g=i[3],p=i[6],x=i[1],y=i[4],_=i[7],I=i[2],E=i[5],A=i[8];return s[0]=a*v+o*x+l*I,s[3]=a*g+o*y+l*E,s[6]=a*p+o*_+l*A,s[1]=c*v+h*x+u*I,s[4]=c*g+h*y+u*E,s[7]=c*p+h*_+u*A,s[2]=d*v+f*x+m*I,s[5]=d*g+f*y+m*E,s[8]=d*p+f*_+m*A,this}multiplyScalar(t){const e=this.elements;return e[0]*=t,e[3]*=t,e[6]*=t,e[1]*=t,e[4]*=t,e[7]*=t,e[2]*=t,e[5]*=t,e[8]*=t,this}determinant(){const t=this.elements,e=t[0],n=t[1],i=t[2],s=t[3],a=t[4],o=t[5],l=t[6],c=t[7],h=t[8];return e*a*h-e*o*c-n*s*h+n*o*l+i*s*c-i*a*l}invert(){const t=this.elements,e=t[0],n=t[1],i=t[2],s=t[3],a=t[4],o=t[5],l=t[6],c=t[7],h=t[8],u=h*a-o*c,d=o*l-h*s,f=c*s-a*l,m=e*u+n*d+i*f;if(m===0)return this.set(0,0,0,0,0,0,0,0,0);const v=1/m;return t[0]=u*v,t[1]=(i*c-h*n)*v,t[2]=(o*n-i*a)*v,t[3]=d*v,t[4]=(h*e-i*l)*v,t[5]=(i*s-o*e)*v,t[6]=f*v,t[7]=(n*l-c*e)*v,t[8]=(a*e-n*s)*v,this}transpose(){let t;const e=this.elements;return t=e[1],e[1]=e[3],e[3]=t,t=e[2],e[2]=e[6],e[6]=t,t=e[5],e[5]=e[7],e[7]=t,this}getNormalMatrix(t){return this.setFromMatrix4(t).invert().transpose()}transposeIntoArray(t){const e=this.elements;return t[0]=e[0],t[1]=e[3],t[2]=e[6],t[3]=e[1],t[4]=e[4],t[5]=e[7],t[6]=e[2],t[7]=e[5],t[8]=e[8],this}setUvTransform(t,e,n,i,s,a,o){const l=Math.cos(s),c=Math.sin(s);return this.set(n*l,n*c,-n*(l*a+c*o)+a+t,-i*c,i*l,-i*(-c*a+l*o)+o+e,0,0,1),this}scale(t,e){return this.premultiply(pa.makeScale(t,e)),this}rotate(t){return this.premultiply(pa.makeRotation(-t)),this}translate(t,e){return this.premultiply(pa.makeTranslation(t,e)),this}makeTranslation(t,e){return t.isVector2?this.set(1,0,t.x,0,1,t.y,0,0,1):this.set(1,0,t,0,1,e,0,0,1),this}makeRotation(t){const e=Math.cos(t),n=Math.sin(t);return this.set(e,-n,0,n,e,0,0,0,1),this}makeScale(t,e){return this.set(t,0,0,0,e,0,0,0,1),this}equals(t){const e=this.elements,n=t.elements;for(let i=0;i<9;i++)if(e[i]!==n[i])return!1;return!0}fromArray(t,e=0){for(let n=0;n<9;n++)this.elements[n]=t[n+e];return this}toArray(t=[],e=0){const n=this.elements;return t[e]=n[0],t[e+1]=n[1],t[e+2]=n[2],t[e+3]=n[3],t[e+4]=n[4],t[e+5]=n[5],t[e+6]=n[6],t[e+7]=n[7],t[e+8]=n[8],t}clone(){return new this.constructor().fromArray(this.elements)}}const pa=new Ut;function Zh(r){for(let t=r.length-1;t>=0;--t)if(r[t]>=65535)return!0;return!1}function Zs(r){return document.createElementNS("http://www.w3.org/1999/xhtml",r)}function jd(){const r=Zs("canvas");return r.style.display="block",r}const Kl={};function zs(r){r in Kl||(Kl[r]=!0,console.warn(r))}function Zd(r,t,e){return new Promise(function(n,i){function s(){switch(r.clientWaitSync(t,r.SYNC_FLUSH_COMMANDS_BIT,0)){case r.WAIT_FAILED:i();break;case r.TIMEOUT_EXPIRED:setTimeout(s,e);break;default:n()}}setTimeout(s,e)})}function Jd(r){const t=r.elements;t[2]=.5*t[2]+.5*t[3],t[6]=.5*t[6]+.5*t[7],t[10]=.5*t[10]+.5*t[11],t[14]=.5*t[14]+.5*t[15]}function Qd(r){const t=r.elements;t[11]===-1?(t[10]=-t[10]-1,t[14]=-t[14]):(t[10]=-t[10],t[14]=-t[14]+1)}const Ht={enabled:!0,workingColorSpace:qe,spaces:{},convert:function(r,t,e){return this.enabled===!1||t===e||!t||!e||(this.spaces[t].transfer===se&&(r.r=jn(r.r),r.g=jn(r.g),r.b=jn(r.b)),this.spaces[t].primaries!==this.spaces[e].primaries&&(r.applyMatrix3(this.spaces[t].toXYZ),r.applyMatrix3(this.spaces[e].fromXYZ)),this.spaces[e].transfer===se&&(r.r=ss(r.r),r.g=ss(r.g),r.b=ss(r.b))),r},fromWorkingColorSpace:function(r,t){return this.convert(r,this.workingColorSpace,t)},toWorkingColorSpace:function(r,t){return this.convert(r,t,this.workingColorSpace)},getPrimaries:function(r){return this.spaces[r].primaries},getTransfer:function(r){return r===di?sa:this.spaces[r].transfer},getLuminanceCoefficients:function(r,t=this.workingColorSpace){return r.fromArray(this.spaces[t].luminanceCoefficients)},define:function(r){Object.assign(this.spaces,r)},_getMatrix:function(r,t,e){return r.copy(this.spaces[t].toXYZ).multiply(this.spaces[e].fromXYZ)},_getDrawingBufferColorSpace:function(r){return this.spaces[r].outputColorSpaceConfig.drawingBufferColorSpace},_getUnpackColorSpace:function(r=this.workingColorSpace){return this.spaces[r].workingColorSpaceConfig.unpackColorSpace}};function jn(r){return r<.04045?r*.0773993808:Math.pow(r*.9478672986+.0521327014,2.4)}function ss(r){return r<.0031308?r*12.92:1.055*Math.pow(r,.41666)-.055}const $l=[.64,.33,.3,.6,.15,.06],jl=[.2126,.7152,.0722],Zl=[.3127,.329],Jl=new Ut().set(.4123908,.3575843,.1804808,.212639,.7151687,.0721923,.0193308,.1191948,.9505322),Ql=new Ut().set(3.2409699,-1.5373832,-.4986108,-.9692436,1.8759675,.0415551,.0556301,-.203977,1.0569715);Ht.define({[qe]:{primaries:$l,whitePoint:Zl,transfer:sa,toXYZ:Jl,fromXYZ:Ql,luminanceCoefficients:jl,workingColorSpaceConfig:{unpackColorSpace:be},outputColorSpaceConfig:{drawingBufferColorSpace:be}},[be]:{primaries:$l,whitePoint:Zl,transfer:se,toXYZ:Jl,fromXYZ:Ql,luminanceCoefficients:jl,outputColorSpaceConfig:{drawingBufferColorSpace:be}}});let Bi;class tf{static getDataURL(t){if(/^data:/i.test(t.src)||typeof HTMLCanvasElement>"u")return t.src;let e;if(t instanceof HTMLCanvasElement)e=t;else{Bi===void 0&&(Bi=Zs("canvas")),Bi.width=t.width,Bi.height=t.height;const n=Bi.getContext("2d");t instanceof ImageData?n.putImageData(t,0,0):n.drawImage(t,0,0,t.width,t.height),e=Bi}return e.width>2048||e.height>2048?(console.warn("THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons",t),e.toDataURL("image/jpeg",.6)):e.toDataURL("image/png")}static sRGBToLinear(t){if(typeof HTMLImageElement<"u"&&t instanceof HTMLImageElement||typeof HTMLCanvasElement<"u"&&t instanceof HTMLCanvasElement||typeof ImageBitmap<"u"&&t instanceof ImageBitmap){const e=Zs("canvas");e.width=t.width,e.height=t.height;const n=e.getContext("2d");n.drawImage(t,0,0,t.width,t.height);const i=n.getImageData(0,0,t.width,t.height),s=i.data;for(let a=0;a<s.length;a++)s[a]=jn(s[a]/255)*255;return n.putImageData(i,0,0),e}else if(t.data){const e=t.data.slice(0);for(let n=0;n<e.length;n++)e instanceof Uint8Array||e instanceof Uint8ClampedArray?e[n]=Math.floor(jn(e[n]/255)*255):e[n]=jn(e[n]);return{data:e,width:t.width,height:t.height}}else return console.warn("THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied."),t}}let ef=0;class Jh{constructor(t=null){this.isSource=!0,Object.defineProperty(this,"id",{value:ef++}),this.uuid=wn(),this.data=t,this.dataReady=!0,this.version=0}set needsUpdate(t){t===!0&&this.version++}toJSON(t){const e=t===void 0||typeof t=="string";if(!e&&t.images[this.uuid]!==void 0)return t.images[this.uuid];const n={uuid:this.uuid,url:""},i=this.data;if(i!==null){let s;if(Array.isArray(i)){s=[];for(let a=0,o=i.length;a<o;a++)i[a].isDataTexture?s.push(ma(i[a].image)):s.push(ma(i[a]))}else s=ma(i);n.url=s}return e||(t.images[this.uuid]=n),n}}function ma(r){return typeof HTMLImageElement<"u"&&r instanceof HTMLImageElement||typeof HTMLCanvasElement<"u"&&r instanceof HTMLCanvasElement||typeof ImageBitmap<"u"&&r instanceof ImageBitmap?tf.getDataURL(r):r.data?{data:Array.from(r.data),width:r.width,height:r.height,type:r.data.constructor.name}:(console.warn("THREE.Texture: Unable to serialize Texture."),{})}let nf=0;class Ce extends _s{constructor(t=Ce.DEFAULT_IMAGE,e=Ce.DEFAULT_MAPPING,n=fi,i=fi,s=tn,a=qn,o=un,l=Jn,c=Ce.DEFAULT_ANISOTROPY,h=di){super(),this.isTexture=!0,Object.defineProperty(this,"id",{value:nf++}),this.uuid=wn(),this.name="",this.source=new Jh(t),this.mipmaps=[],this.mapping=e,this.channel=0,this.wrapS=n,this.wrapT=i,this.magFilter=s,this.minFilter=a,this.anisotropy=c,this.format=o,this.internalFormat=null,this.type=l,this.offset=new nt(0,0),this.repeat=new nt(1,1),this.center=new nt(0,0),this.rotation=0,this.matrixAutoUpdate=!0,this.matrix=new Ut,this.generateMipmaps=!0,this.premultiplyAlpha=!1,this.flipY=!0,this.unpackAlignment=4,this.colorSpace=h,this.userData={},this.version=0,this.onUpdate=null,this.isRenderTargetTexture=!1,this.pmremVersion=0}get image(){return this.source.data}set image(t=null){this.source.data=t}updateMatrix(){this.matrix.setUvTransform(this.offset.x,this.offset.y,this.repeat.x,this.repeat.y,this.rotation,this.center.x,this.center.y)}clone(){return new this.constructor().copy(this)}copy(t){return this.name=t.name,this.source=t.source,this.mipmaps=t.mipmaps.slice(0),this.mapping=t.mapping,this.channel=t.channel,this.wrapS=t.wrapS,this.wrapT=t.wrapT,this.magFilter=t.magFilter,this.minFilter=t.minFilter,this.anisotropy=t.anisotropy,this.format=t.format,this.internalFormat=t.internalFormat,this.type=t.type,this.offset.copy(t.offset),this.repeat.copy(t.repeat),this.center.copy(t.center),this.rotation=t.rotation,this.matrixAutoUpdate=t.matrixAutoUpdate,this.matrix.copy(t.matrix),this.generateMipmaps=t.generateMipmaps,this.premultiplyAlpha=t.premultiplyAlpha,this.flipY=t.flipY,this.unpackAlignment=t.unpackAlignment,this.colorSpace=t.colorSpace,this.userData=JSON.parse(JSON.stringify(t.userData)),this.needsUpdate=!0,this}toJSON(t){const e=t===void 0||typeof t=="string";if(!e&&t.textures[this.uuid]!==void 0)return t.textures[this.uuid];const n={metadata:{version:4.6,type:"Texture",generator:"Texture.toJSON"},uuid:this.uuid,name:this.name,image:this.source.toJSON(t).uuid,mapping:this.mapping,channel:this.channel,repeat:[this.repeat.x,this.repeat.y],offset:[this.offset.x,this.offset.y],center:[this.center.x,this.center.y],rotation:this.rotation,wrap:[this.wrapS,this.wrapT],format:this.format,internalFormat:this.internalFormat,type:this.type,colorSpace:this.colorSpace,minFilter:this.minFilter,magFilter:this.magFilter,anisotropy:this.anisotropy,flipY:this.flipY,generateMipmaps:this.generateMipmaps,premultiplyAlpha:this.premultiplyAlpha,unpackAlignment:this.unpackAlignment};return Object.keys(this.userData).length>0&&(n.userData=this.userData),e||(t.textures[this.uuid]=n),n}dispose(){this.dispatchEvent({type:"dispose"})}transformUv(t){if(this.mapping!==Oh)return t;if(t.applyMatrix3(this.matrix),t.x<0||t.x>1)switch(this.wrapS){case vi:t.x=t.x-Math.floor(t.x);break;case fi:t.x=t.x<0?0:1;break;case $r:Math.abs(Math.floor(t.x)%2)===1?t.x=Math.ceil(t.x)-t.x:t.x=t.x-Math.floor(t.x);break}if(t.y<0||t.y>1)switch(this.wrapT){case vi:t.y=t.y-Math.floor(t.y);break;case fi:t.y=t.y<0?0:1;break;case $r:Math.abs(Math.floor(t.y)%2)===1?t.y=Math.ceil(t.y)-t.y:t.y=t.y-Math.floor(t.y);break}return this.flipY&&(t.y=1-t.y),t}set needsUpdate(t){t===!0&&(this.version++,this.source.needsUpdate=!0)}set needsPMREMUpdate(t){t===!0&&this.pmremVersion++}}Ce.DEFAULT_IMAGE=null;Ce.DEFAULT_MAPPING=Oh;Ce.DEFAULT_ANISOTROPY=1;class Qt{constructor(t=0,e=0,n=0,i=1){Qt.prototype.isVector4=!0,this.x=t,this.y=e,this.z=n,this.w=i}get width(){return this.z}set width(t){this.z=t}get height(){return this.w}set height(t){this.w=t}set(t,e,n,i){return this.x=t,this.y=e,this.z=n,this.w=i,this}setScalar(t){return this.x=t,this.y=t,this.z=t,this.w=t,this}setX(t){return this.x=t,this}setY(t){return this.y=t,this}setZ(t){return this.z=t,this}setW(t){return this.w=t,this}setComponent(t,e){switch(t){case 0:this.x=e;break;case 1:this.y=e;break;case 2:this.z=e;break;case 3:this.w=e;break;default:throw new Error("index is out of range: "+t)}return this}getComponent(t){switch(t){case 0:return this.x;case 1:return this.y;case 2:return this.z;case 3:return this.w;default:throw new Error("index is out of range: "+t)}}clone(){return new this.constructor(this.x,this.y,this.z,this.w)}copy(t){return this.x=t.x,this.y=t.y,this.z=t.z,this.w=t.w!==void 0?t.w:1,this}add(t){return this.x+=t.x,this.y+=t.y,this.z+=t.z,this.w+=t.w,this}addScalar(t){return this.x+=t,this.y+=t,this.z+=t,this.w+=t,this}addVectors(t,e){return this.x=t.x+e.x,this.y=t.y+e.y,this.z=t.z+e.z,this.w=t.w+e.w,this}addScaledVector(t,e){return this.x+=t.x*e,this.y+=t.y*e,this.z+=t.z*e,this.w+=t.w*e,this}sub(t){return this.x-=t.x,this.y-=t.y,this.z-=t.z,this.w-=t.w,this}subScalar(t){return this.x-=t,this.y-=t,this.z-=t,this.w-=t,this}subVectors(t,e){return this.x=t.x-e.x,this.y=t.y-e.y,this.z=t.z-e.z,this.w=t.w-e.w,this}multiply(t){return this.x*=t.x,this.y*=t.y,this.z*=t.z,this.w*=t.w,this}multiplyScalar(t){return this.x*=t,this.y*=t,this.z*=t,this.w*=t,this}applyMatrix4(t){const e=this.x,n=this.y,i=this.z,s=this.w,a=t.elements;return this.x=a[0]*e+a[4]*n+a[8]*i+a[12]*s,this.y=a[1]*e+a[5]*n+a[9]*i+a[13]*s,this.z=a[2]*e+a[6]*n+a[10]*i+a[14]*s,this.w=a[3]*e+a[7]*n+a[11]*i+a[15]*s,this}divide(t){return this.x/=t.x,this.y/=t.y,this.z/=t.z,this.w/=t.w,this}divideScalar(t){return this.multiplyScalar(1/t)}setAxisAngleFromQuaternion(t){this.w=2*Math.acos(t.w);const e=Math.sqrt(1-t.w*t.w);return e<1e-4?(this.x=1,this.y=0,this.z=0):(this.x=t.x/e,this.y=t.y/e,this.z=t.z/e),this}setAxisAngleFromRotationMatrix(t){let e,n,i,s;const l=t.elements,c=l[0],h=l[4],u=l[8],d=l[1],f=l[5],m=l[9],v=l[2],g=l[6],p=l[10];if(Math.abs(h-d)<.01&&Math.abs(u-v)<.01&&Math.abs(m-g)<.01){if(Math.abs(h+d)<.1&&Math.abs(u+v)<.1&&Math.abs(m+g)<.1&&Math.abs(c+f+p-3)<.1)return this.set(1,0,0,0),this;e=Math.PI;const y=(c+1)/2,_=(f+1)/2,I=(p+1)/2,E=(h+d)/4,A=(u+v)/4,C=(m+g)/4;return y>_&&y>I?y<.01?(n=0,i=.707106781,s=.707106781):(n=Math.sqrt(y),i=E/n,s=A/n):_>I?_<.01?(n=.707106781,i=0,s=.707106781):(i=Math.sqrt(_),n=E/i,s=C/i):I<.01?(n=.707106781,i=.707106781,s=0):(s=Math.sqrt(I),n=A/s,i=C/s),this.set(n,i,s,e),this}let x=Math.sqrt((g-m)*(g-m)+(u-v)*(u-v)+(d-h)*(d-h));return Math.abs(x)<.001&&(x=1),this.x=(g-m)/x,this.y=(u-v)/x,this.z=(d-h)/x,this.w=Math.acos((c+f+p-1)/2),this}setFromMatrixPosition(t){const e=t.elements;return this.x=e[12],this.y=e[13],this.z=e[14],this.w=e[15],this}min(t){return this.x=Math.min(this.x,t.x),this.y=Math.min(this.y,t.y),this.z=Math.min(this.z,t.z),this.w=Math.min(this.w,t.w),this}max(t){return this.x=Math.max(this.x,t.x),this.y=Math.max(this.y,t.y),this.z=Math.max(this.z,t.z),this.w=Math.max(this.w,t.w),this}clamp(t,e){return this.x=Math.max(t.x,Math.min(e.x,this.x)),this.y=Math.max(t.y,Math.min(e.y,this.y)),this.z=Math.max(t.z,Math.min(e.z,this.z)),this.w=Math.max(t.w,Math.min(e.w,this.w)),this}clampScalar(t,e){return this.x=Math.max(t,Math.min(e,this.x)),this.y=Math.max(t,Math.min(e,this.y)),this.z=Math.max(t,Math.min(e,this.z)),this.w=Math.max(t,Math.min(e,this.w)),this}clampLength(t,e){const n=this.length();return this.divideScalar(n||1).multiplyScalar(Math.max(t,Math.min(e,n)))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this.z=Math.floor(this.z),this.w=Math.floor(this.w),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this.z=Math.ceil(this.z),this.w=Math.ceil(this.w),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this.z=Math.round(this.z),this.w=Math.round(this.w),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this.z=Math.trunc(this.z),this.w=Math.trunc(this.w),this}negate(){return this.x=-this.x,this.y=-this.y,this.z=-this.z,this.w=-this.w,this}dot(t){return this.x*t.x+this.y*t.y+this.z*t.z+this.w*t.w}lengthSq(){return this.x*this.x+this.y*this.y+this.z*this.z+this.w*this.w}length(){return Math.sqrt(this.x*this.x+this.y*this.y+this.z*this.z+this.w*this.w)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)+Math.abs(this.z)+Math.abs(this.w)}normalize(){return this.divideScalar(this.length()||1)}setLength(t){return this.normalize().multiplyScalar(t)}lerp(t,e){return this.x+=(t.x-this.x)*e,this.y+=(t.y-this.y)*e,this.z+=(t.z-this.z)*e,this.w+=(t.w-this.w)*e,this}lerpVectors(t,e,n){return this.x=t.x+(e.x-t.x)*n,this.y=t.y+(e.y-t.y)*n,this.z=t.z+(e.z-t.z)*n,this.w=t.w+(e.w-t.w)*n,this}equals(t){return t.x===this.x&&t.y===this.y&&t.z===this.z&&t.w===this.w}fromArray(t,e=0){return this.x=t[e],this.y=t[e+1],this.z=t[e+2],this.w=t[e+3],this}toArray(t=[],e=0){return t[e]=this.x,t[e+1]=this.y,t[e+2]=this.z,t[e+3]=this.w,t}fromBufferAttribute(t,e){return this.x=t.getX(e),this.y=t.getY(e),this.z=t.getZ(e),this.w=t.getW(e),this}random(){return this.x=Math.random(),this.y=Math.random(),this.z=Math.random(),this.w=Math.random(),this}*[Symbol.iterator](){yield this.x,yield this.y,yield this.z,yield this.w}}class sf extends _s{constructor(t=1,e=1,n={}){super(),this.isRenderTarget=!0,this.width=t,this.height=e,this.depth=1,this.scissor=new Qt(0,0,t,e),this.scissorTest=!1,this.viewport=new Qt(0,0,t,e);const i={width:t,height:e,depth:1};n=Object.assign({generateMipmaps:!1,internalFormat:null,minFilter:tn,depthBuffer:!0,stencilBuffer:!1,resolveDepthBuffer:!0,resolveStencilBuffer:!0,depthTexture:null,samples:0,count:1},n);const s=new Ce(i,n.mapping,n.wrapS,n.wrapT,n.magFilter,n.minFilter,n.format,n.type,n.anisotropy,n.colorSpace);s.flipY=!1,s.generateMipmaps=n.generateMipmaps,s.internalFormat=n.internalFormat,this.textures=[];const a=n.count;for(let o=0;o<a;o++)this.textures[o]=s.clone(),this.textures[o].isRenderTargetTexture=!0;this.depthBuffer=n.depthBuffer,this.stencilBuffer=n.stencilBuffer,this.resolveDepthBuffer=n.resolveDepthBuffer,this.resolveStencilBuffer=n.resolveStencilBuffer,this.depthTexture=n.depthTexture,this.samples=n.samples}get texture(){return this.textures[0]}set texture(t){this.textures[0]=t}setSize(t,e,n=1){if(this.width!==t||this.height!==e||this.depth!==n){this.width=t,this.height=e,this.depth=n;for(let i=0,s=this.textures.length;i<s;i++)this.textures[i].image.width=t,this.textures[i].image.height=e,this.textures[i].image.depth=n;this.dispose()}this.viewport.set(0,0,t,e),this.scissor.set(0,0,t,e)}clone(){return new this.constructor().copy(this)}copy(t){this.width=t.width,this.height=t.height,this.depth=t.depth,this.scissor.copy(t.scissor),this.scissorTest=t.scissorTest,this.viewport.copy(t.viewport),this.textures.length=0;for(let n=0,i=t.textures.length;n<i;n++)this.textures[n]=t.textures[n].clone(),this.textures[n].isRenderTargetTexture=!0;const e=Object.assign({},t.texture.image);return this.texture.source=new Jh(e),this.depthBuffer=t.depthBuffer,this.stencilBuffer=t.stencilBuffer,this.resolveDepthBuffer=t.resolveDepthBuffer,this.resolveStencilBuffer=t.resolveStencilBuffer,t.depthTexture!==null&&(this.depthTexture=t.depthTexture.clone()),this.samples=t.samples,this}dispose(){this.dispatchEvent({type:"dispose"})}}class fn extends sf{constructor(t=1,e=1,n={}){super(t,e,n),this.isWebGLRenderTarget=!0}}class Qh extends Ce{constructor(t=null,e=1,n=1,i=1){super(null),this.isDataArrayTexture=!0,this.image={data:t,width:e,height:n,depth:i},this.magFilter=Xe,this.minFilter=Xe,this.wrapR=fi,this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1,this.layerUpdates=new Set}addLayerUpdate(t){this.layerUpdates.add(t)}clearLayerUpdates(){this.layerUpdates.clear()}}class rf extends Ce{constructor(t=null,e=1,n=1,i=1){super(null),this.isData3DTexture=!0,this.image={data:t,width:e,height:n,depth:i},this.magFilter=Xe,this.minFilter=Xe,this.wrapR=fi,this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1}}class xi{constructor(t=0,e=0,n=0,i=1){this.isQuaternion=!0,this._x=t,this._y=e,this._z=n,this._w=i}static slerpFlat(t,e,n,i,s,a,o){let l=n[i+0],c=n[i+1],h=n[i+2],u=n[i+3];const d=s[a+0],f=s[a+1],m=s[a+2],v=s[a+3];if(o===0){t[e+0]=l,t[e+1]=c,t[e+2]=h,t[e+3]=u;return}if(o===1){t[e+0]=d,t[e+1]=f,t[e+2]=m,t[e+3]=v;return}if(u!==v||l!==d||c!==f||h!==m){let g=1-o;const p=l*d+c*f+h*m+u*v,x=p>=0?1:-1,y=1-p*p;if(y>Number.EPSILON){const I=Math.sqrt(y),E=Math.atan2(I,p*x);g=Math.sin(g*E)/I,o=Math.sin(o*E)/I}const _=o*x;if(l=l*g+d*_,c=c*g+f*_,h=h*g+m*_,u=u*g+v*_,g===1-o){const I=1/Math.sqrt(l*l+c*c+h*h+u*u);l*=I,c*=I,h*=I,u*=I}}t[e]=l,t[e+1]=c,t[e+2]=h,t[e+3]=u}static multiplyQuaternionsFlat(t,e,n,i,s,a){const o=n[i],l=n[i+1],c=n[i+2],h=n[i+3],u=s[a],d=s[a+1],f=s[a+2],m=s[a+3];return t[e]=o*m+h*u+l*f-c*d,t[e+1]=l*m+h*d+c*u-o*f,t[e+2]=c*m+h*f+o*d-l*u,t[e+3]=h*m-o*u-l*d-c*f,t}get x(){return this._x}set x(t){this._x=t,this._onChangeCallback()}get y(){return this._y}set y(t){this._y=t,this._onChangeCallback()}get z(){return this._z}set z(t){this._z=t,this._onChangeCallback()}get w(){return this._w}set w(t){this._w=t,this._onChangeCallback()}set(t,e,n,i){return this._x=t,this._y=e,this._z=n,this._w=i,this._onChangeCallback(),this}clone(){return new this.constructor(this._x,this._y,this._z,this._w)}copy(t){return this._x=t.x,this._y=t.y,this._z=t.z,this._w=t.w,this._onChangeCallback(),this}setFromEuler(t,e=!0){const n=t._x,i=t._y,s=t._z,a=t._order,o=Math.cos,l=Math.sin,c=o(n/2),h=o(i/2),u=o(s/2),d=l(n/2),f=l(i/2),m=l(s/2);switch(a){case"XYZ":this._x=d*h*u+c*f*m,this._y=c*f*u-d*h*m,this._z=c*h*m+d*f*u,this._w=c*h*u-d*f*m;break;case"YXZ":this._x=d*h*u+c*f*m,this._y=c*f*u-d*h*m,this._z=c*h*m-d*f*u,this._w=c*h*u+d*f*m;break;case"ZXY":this._x=d*h*u-c*f*m,this._y=c*f*u+d*h*m,this._z=c*h*m+d*f*u,this._w=c*h*u-d*f*m;break;case"ZYX":this._x=d*h*u-c*f*m,this._y=c*f*u+d*h*m,this._z=c*h*m-d*f*u,this._w=c*h*u+d*f*m;break;case"YZX":this._x=d*h*u+c*f*m,this._y=c*f*u+d*h*m,this._z=c*h*m-d*f*u,this._w=c*h*u-d*f*m;break;case"XZY":this._x=d*h*u-c*f*m,this._y=c*f*u-d*h*m,this._z=c*h*m+d*f*u,this._w=c*h*u+d*f*m;break;default:console.warn("THREE.Quaternion: .setFromEuler() encountered an unknown order: "+a)}return e===!0&&this._onChangeCallback(),this}setFromAxisAngle(t,e){const n=e/2,i=Math.sin(n);return this._x=t.x*i,this._y=t.y*i,this._z=t.z*i,this._w=Math.cos(n),this._onChangeCallback(),this}setFromRotationMatrix(t){const e=t.elements,n=e[0],i=e[4],s=e[8],a=e[1],o=e[5],l=e[9],c=e[2],h=e[6],u=e[10],d=n+o+u;if(d>0){const f=.5/Math.sqrt(d+1);this._w=.25/f,this._x=(h-l)*f,this._y=(s-c)*f,this._z=(a-i)*f}else if(n>o&&n>u){const f=2*Math.sqrt(1+n-o-u);this._w=(h-l)/f,this._x=.25*f,this._y=(i+a)/f,this._z=(s+c)/f}else if(o>u){const f=2*Math.sqrt(1+o-n-u);this._w=(s-c)/f,this._x=(i+a)/f,this._y=.25*f,this._z=(l+h)/f}else{const f=2*Math.sqrt(1+u-n-o);this._w=(a-i)/f,this._x=(s+c)/f,this._y=(l+h)/f,this._z=.25*f}return this._onChangeCallback(),this}setFromUnitVectors(t,e){let n=t.dot(e)+1;return n<Number.EPSILON?(n=0,Math.abs(t.x)>Math.abs(t.z)?(this._x=-t.y,this._y=t.x,this._z=0,this._w=n):(this._x=0,this._y=-t.z,this._z=t.y,this._w=n)):(this._x=t.y*e.z-t.z*e.y,this._y=t.z*e.x-t.x*e.z,this._z=t.x*e.y-t.y*e.x,this._w=n),this.normalize()}angleTo(t){return 2*Math.acos(Math.abs(Ae(this.dot(t),-1,1)))}rotateTowards(t,e){const n=this.angleTo(t);if(n===0)return this;const i=Math.min(1,e/n);return this.slerp(t,i),this}identity(){return this.set(0,0,0,1)}invert(){return this.conjugate()}conjugate(){return this._x*=-1,this._y*=-1,this._z*=-1,this._onChangeCallback(),this}dot(t){return this._x*t._x+this._y*t._y+this._z*t._z+this._w*t._w}lengthSq(){return this._x*this._x+this._y*this._y+this._z*this._z+this._w*this._w}length(){return Math.sqrt(this._x*this._x+this._y*this._y+this._z*this._z+this._w*this._w)}normalize(){let t=this.length();return t===0?(this._x=0,this._y=0,this._z=0,this._w=1):(t=1/t,this._x=this._x*t,this._y=this._y*t,this._z=this._z*t,this._w=this._w*t),this._onChangeCallback(),this}multiply(t){return this.multiplyQuaternions(this,t)}premultiply(t){return this.multiplyQuaternions(t,this)}multiplyQuaternions(t,e){const n=t._x,i=t._y,s=t._z,a=t._w,o=e._x,l=e._y,c=e._z,h=e._w;return this._x=n*h+a*o+i*c-s*l,this._y=i*h+a*l+s*o-n*c,this._z=s*h+a*c+n*l-i*o,this._w=a*h-n*o-i*l-s*c,this._onChangeCallback(),this}slerp(t,e){if(e===0)return this;if(e===1)return this.copy(t);const n=this._x,i=this._y,s=this._z,a=this._w;let o=a*t._w+n*t._x+i*t._y+s*t._z;if(o<0?(this._w=-t._w,this._x=-t._x,this._y=-t._y,this._z=-t._z,o=-o):this.copy(t),o>=1)return this._w=a,this._x=n,this._y=i,this._z=s,this;const l=1-o*o;if(l<=Number.EPSILON){const f=1-e;return this._w=f*a+e*this._w,this._x=f*n+e*this._x,this._y=f*i+e*this._y,this._z=f*s+e*this._z,this.normalize(),this}const c=Math.sqrt(l),h=Math.atan2(c,o),u=Math.sin((1-e)*h)/c,d=Math.sin(e*h)/c;return this._w=a*u+this._w*d,this._x=n*u+this._x*d,this._y=i*u+this._y*d,this._z=s*u+this._z*d,this._onChangeCallback(),this}slerpQuaternions(t,e,n){return this.copy(t).slerp(e,n)}random(){const t=2*Math.PI*Math.random(),e=2*Math.PI*Math.random(),n=Math.random(),i=Math.sqrt(1-n),s=Math.sqrt(n);return this.set(i*Math.sin(t),i*Math.cos(t),s*Math.sin(e),s*Math.cos(e))}equals(t){return t._x===this._x&&t._y===this._y&&t._z===this._z&&t._w===this._w}fromArray(t,e=0){return this._x=t[e],this._y=t[e+1],this._z=t[e+2],this._w=t[e+3],this._onChangeCallback(),this}toArray(t=[],e=0){return t[e]=this._x,t[e+1]=this._y,t[e+2]=this._z,t[e+3]=this._w,t}fromBufferAttribute(t,e){return this._x=t.getX(e),this._y=t.getY(e),this._z=t.getZ(e),this._w=t.getW(e),this._onChangeCallback(),this}toJSON(){return this.toArray()}_onChange(t){return this._onChangeCallback=t,this}_onChangeCallback(){}*[Symbol.iterator](){yield this._x,yield this._y,yield this._z,yield this._w}}class P{constructor(t=0,e=0,n=0){P.prototype.isVector3=!0,this.x=t,this.y=e,this.z=n}set(t,e,n){return n===void 0&&(n=this.z),this.x=t,this.y=e,this.z=n,this}setScalar(t){return this.x=t,this.y=t,this.z=t,this}setX(t){return this.x=t,this}setY(t){return this.y=t,this}setZ(t){return this.z=t,this}setComponent(t,e){switch(t){case 0:this.x=e;break;case 1:this.y=e;break;case 2:this.z=e;break;default:throw new Error("index is out of range: "+t)}return this}getComponent(t){switch(t){case 0:return this.x;case 1:return this.y;case 2:return this.z;default:throw new Error("index is out of range: "+t)}}clone(){return new this.constructor(this.x,this.y,this.z)}copy(t){return this.x=t.x,this.y=t.y,this.z=t.z,this}add(t){return this.x+=t.x,this.y+=t.y,this.z+=t.z,this}addScalar(t){return this.x+=t,this.y+=t,this.z+=t,this}addVectors(t,e){return this.x=t.x+e.x,this.y=t.y+e.y,this.z=t.z+e.z,this}addScaledVector(t,e){return this.x+=t.x*e,this.y+=t.y*e,this.z+=t.z*e,this}sub(t){return this.x-=t.x,this.y-=t.y,this.z-=t.z,this}subScalar(t){return this.x-=t,this.y-=t,this.z-=t,this}subVectors(t,e){return this.x=t.x-e.x,this.y=t.y-e.y,this.z=t.z-e.z,this}multiply(t){return this.x*=t.x,this.y*=t.y,this.z*=t.z,this}multiplyScalar(t){return this.x*=t,this.y*=t,this.z*=t,this}multiplyVectors(t,e){return this.x=t.x*e.x,this.y=t.y*e.y,this.z=t.z*e.z,this}applyEuler(t){return this.applyQuaternion(tc.setFromEuler(t))}applyAxisAngle(t,e){return this.applyQuaternion(tc.setFromAxisAngle(t,e))}applyMatrix3(t){const e=this.x,n=this.y,i=this.z,s=t.elements;return this.x=s[0]*e+s[3]*n+s[6]*i,this.y=s[1]*e+s[4]*n+s[7]*i,this.z=s[2]*e+s[5]*n+s[8]*i,this}applyNormalMatrix(t){return this.applyMatrix3(t).normalize()}applyMatrix4(t){const e=this.x,n=this.y,i=this.z,s=t.elements,a=1/(s[3]*e+s[7]*n+s[11]*i+s[15]);return this.x=(s[0]*e+s[4]*n+s[8]*i+s[12])*a,this.y=(s[1]*e+s[5]*n+s[9]*i+s[13])*a,this.z=(s[2]*e+s[6]*n+s[10]*i+s[14])*a,this}applyQuaternion(t){const e=this.x,n=this.y,i=this.z,s=t.x,a=t.y,o=t.z,l=t.w,c=2*(a*i-o*n),h=2*(o*e-s*i),u=2*(s*n-a*e);return this.x=e+l*c+a*u-o*h,this.y=n+l*h+o*c-s*u,this.z=i+l*u+s*h-a*c,this}project(t){return this.applyMatrix4(t.matrixWorldInverse).applyMatrix4(t.projectionMatrix)}unproject(t){return this.applyMatrix4(t.projectionMatrixInverse).applyMatrix4(t.matrixWorld)}transformDirection(t){const e=this.x,n=this.y,i=this.z,s=t.elements;return this.x=s[0]*e+s[4]*n+s[8]*i,this.y=s[1]*e+s[5]*n+s[9]*i,this.z=s[2]*e+s[6]*n+s[10]*i,this.normalize()}divide(t){return this.x/=t.x,this.y/=t.y,this.z/=t.z,this}divideScalar(t){return this.multiplyScalar(1/t)}min(t){return this.x=Math.min(this.x,t.x),this.y=Math.min(this.y,t.y),this.z=Math.min(this.z,t.z),this}max(t){return this.x=Math.max(this.x,t.x),this.y=Math.max(this.y,t.y),this.z=Math.max(this.z,t.z),this}clamp(t,e){return this.x=Math.max(t.x,Math.min(e.x,this.x)),this.y=Math.max(t.y,Math.min(e.y,this.y)),this.z=Math.max(t.z,Math.min(e.z,this.z)),this}clampScalar(t,e){return this.x=Math.max(t,Math.min(e,this.x)),this.y=Math.max(t,Math.min(e,this.y)),this.z=Math.max(t,Math.min(e,this.z)),this}clampLength(t,e){const n=this.length();return this.divideScalar(n||1).multiplyScalar(Math.max(t,Math.min(e,n)))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this.z=Math.floor(this.z),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this.z=Math.ceil(this.z),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this.z=Math.round(this.z),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this.z=Math.trunc(this.z),this}negate(){return this.x=-this.x,this.y=-this.y,this.z=-this.z,this}dot(t){return this.x*t.x+this.y*t.y+this.z*t.z}lengthSq(){return this.x*this.x+this.y*this.y+this.z*this.z}length(){return Math.sqrt(this.x*this.x+this.y*this.y+this.z*this.z)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)+Math.abs(this.z)}normalize(){return this.divideScalar(this.length()||1)}setLength(t){return this.normalize().multiplyScalar(t)}lerp(t,e){return this.x+=(t.x-this.x)*e,this.y+=(t.y-this.y)*e,this.z+=(t.z-this.z)*e,this}lerpVectors(t,e,n){return this.x=t.x+(e.x-t.x)*n,this.y=t.y+(e.y-t.y)*n,this.z=t.z+(e.z-t.z)*n,this}cross(t){return this.crossVectors(this,t)}crossVectors(t,e){const n=t.x,i=t.y,s=t.z,a=e.x,o=e.y,l=e.z;return this.x=i*l-s*o,this.y=s*a-n*l,this.z=n*o-i*a,this}projectOnVector(t){const e=t.lengthSq();if(e===0)return this.set(0,0,0);const n=t.dot(this)/e;return this.copy(t).multiplyScalar(n)}projectOnPlane(t){return ga.copy(this).projectOnVector(t),this.sub(ga)}reflect(t){return this.sub(ga.copy(t).multiplyScalar(2*this.dot(t)))}angleTo(t){const e=Math.sqrt(this.lengthSq()*t.lengthSq());if(e===0)return Math.PI/2;const n=this.dot(t)/e;return Math.acos(Ae(n,-1,1))}distanceTo(t){return Math.sqrt(this.distanceToSquared(t))}distanceToSquared(t){const e=this.x-t.x,n=this.y-t.y,i=this.z-t.z;return e*e+n*n+i*i}manhattanDistanceTo(t){return Math.abs(this.x-t.x)+Math.abs(this.y-t.y)+Math.abs(this.z-t.z)}setFromSpherical(t){return this.setFromSphericalCoords(t.radius,t.phi,t.theta)}setFromSphericalCoords(t,e,n){const i=Math.sin(e)*t;return this.x=i*Math.sin(n),this.y=Math.cos(e)*t,this.z=i*Math.cos(n),this}setFromCylindrical(t){return this.setFromCylindricalCoords(t.radius,t.theta,t.y)}setFromCylindricalCoords(t,e,n){return this.x=t*Math.sin(e),this.y=n,this.z=t*Math.cos(e),this}setFromMatrixPosition(t){const e=t.elements;return this.x=e[12],this.y=e[13],this.z=e[14],this}setFromMatrixScale(t){const e=this.setFromMatrixColumn(t,0).length(),n=this.setFromMatrixColumn(t,1).length(),i=this.setFromMatrixColumn(t,2).length();return this.x=e,this.y=n,this.z=i,this}setFromMatrixColumn(t,e){return this.fromArray(t.elements,e*4)}setFromMatrix3Column(t,e){return this.fromArray(t.elements,e*3)}setFromEuler(t){return this.x=t._x,this.y=t._y,this.z=t._z,this}setFromColor(t){return this.x=t.r,this.y=t.g,this.z=t.b,this}equals(t){return t.x===this.x&&t.y===this.y&&t.z===this.z}fromArray(t,e=0){return this.x=t[e],this.y=t[e+1],this.z=t[e+2],this}toArray(t=[],e=0){return t[e]=this.x,t[e+1]=this.y,t[e+2]=this.z,t}fromBufferAttribute(t,e){return this.x=t.getX(e),this.y=t.getY(e),this.z=t.getZ(e),this}random(){return this.x=Math.random(),this.y=Math.random(),this.z=Math.random(),this}randomDirection(){const t=Math.random()*Math.PI*2,e=Math.random()*2-1,n=Math.sqrt(1-e*e);return this.x=n*Math.cos(t),this.y=e,this.z=n*Math.sin(t),this}*[Symbol.iterator](){yield this.x,yield this.y,yield this.z}}const ga=new P,tc=new xi;class Qn{constructor(t=new P(1/0,1/0,1/0),e=new P(-1/0,-1/0,-1/0)){this.isBox3=!0,this.min=t,this.max=e}set(t,e){return this.min.copy(t),this.max.copy(e),this}setFromArray(t){this.makeEmpty();for(let e=0,n=t.length;e<n;e+=3)this.expandByPoint(gn.fromArray(t,e));return this}setFromBufferAttribute(t){this.makeEmpty();for(let e=0,n=t.count;e<n;e++)this.expandByPoint(gn.fromBufferAttribute(t,e));return this}setFromPoints(t){this.makeEmpty();for(let e=0,n=t.length;e<n;e++)this.expandByPoint(t[e]);return this}setFromCenterAndSize(t,e){const n=gn.copy(e).multiplyScalar(.5);return this.min.copy(t).sub(n),this.max.copy(t).add(n),this}setFromObject(t,e=!1){return this.makeEmpty(),this.expandByObject(t,e)}clone(){return new this.constructor().copy(this)}copy(t){return this.min.copy(t.min),this.max.copy(t.max),this}makeEmpty(){return this.min.x=this.min.y=this.min.z=1/0,this.max.x=this.max.y=this.max.z=-1/0,this}isEmpty(){return this.max.x<this.min.x||this.max.y<this.min.y||this.max.z<this.min.z}getCenter(t){return this.isEmpty()?t.set(0,0,0):t.addVectors(this.min,this.max).multiplyScalar(.5)}getSize(t){return this.isEmpty()?t.set(0,0,0):t.subVectors(this.max,this.min)}expandByPoint(t){return this.min.min(t),this.max.max(t),this}expandByVector(t){return this.min.sub(t),this.max.add(t),this}expandByScalar(t){return this.min.addScalar(-t),this.max.addScalar(t),this}expandByObject(t,e=!1){t.updateWorldMatrix(!1,!1);const n=t.geometry;if(n!==void 0){const s=n.getAttribute("position");if(e===!0&&s!==void 0&&t.isInstancedMesh!==!0)for(let a=0,o=s.count;a<o;a++)t.isMesh===!0?t.getVertexPosition(a,gn):gn.fromBufferAttribute(s,a),gn.applyMatrix4(t.matrixWorld),this.expandByPoint(gn);else t.boundingBox!==void 0?(t.boundingBox===null&&t.computeBoundingBox(),cr.copy(t.boundingBox)):(n.boundingBox===null&&n.computeBoundingBox(),cr.copy(n.boundingBox)),cr.applyMatrix4(t.matrixWorld),this.union(cr)}const i=t.children;for(let s=0,a=i.length;s<a;s++)this.expandByObject(i[s],e);return this}containsPoint(t){return t.x>=this.min.x&&t.x<=this.max.x&&t.y>=this.min.y&&t.y<=this.max.y&&t.z>=this.min.z&&t.z<=this.max.z}containsBox(t){return this.min.x<=t.min.x&&t.max.x<=this.max.x&&this.min.y<=t.min.y&&t.max.y<=this.max.y&&this.min.z<=t.min.z&&t.max.z<=this.max.z}getParameter(t,e){return e.set((t.x-this.min.x)/(this.max.x-this.min.x),(t.y-this.min.y)/(this.max.y-this.min.y),(t.z-this.min.z)/(this.max.z-this.min.z))}intersectsBox(t){return t.max.x>=this.min.x&&t.min.x<=this.max.x&&t.max.y>=this.min.y&&t.min.y<=this.max.y&&t.max.z>=this.min.z&&t.min.z<=this.max.z}intersectsSphere(t){return this.clampPoint(t.center,gn),gn.distanceToSquared(t.center)<=t.radius*t.radius}intersectsPlane(t){let e,n;return t.normal.x>0?(e=t.normal.x*this.min.x,n=t.normal.x*this.max.x):(e=t.normal.x*this.max.x,n=t.normal.x*this.min.x),t.normal.y>0?(e+=t.normal.y*this.min.y,n+=t.normal.y*this.max.y):(e+=t.normal.y*this.max.y,n+=t.normal.y*this.min.y),t.normal.z>0?(e+=t.normal.z*this.min.z,n+=t.normal.z*this.max.z):(e+=t.normal.z*this.max.z,n+=t.normal.z*this.min.z),e<=-t.constant&&n>=-t.constant}intersectsTriangle(t){if(this.isEmpty())return!1;this.getCenter(As),hr.subVectors(this.max,As),zi.subVectors(t.a,As),Hi.subVectors(t.b,As),Vi.subVectors(t.c,As),ni.subVectors(Hi,zi),ii.subVectors(Vi,Hi),Mi.subVectors(zi,Vi);let e=[0,-ni.z,ni.y,0,-ii.z,ii.y,0,-Mi.z,Mi.y,ni.z,0,-ni.x,ii.z,0,-ii.x,Mi.z,0,-Mi.x,-ni.y,ni.x,0,-ii.y,ii.x,0,-Mi.y,Mi.x,0];return!va(e,zi,Hi,Vi,hr)||(e=[1,0,0,0,1,0,0,0,1],!va(e,zi,Hi,Vi,hr))?!1:(ur.crossVectors(ni,ii),e=[ur.x,ur.y,ur.z],va(e,zi,Hi,Vi,hr))}clampPoint(t,e){return e.copy(t).clamp(this.min,this.max)}distanceToPoint(t){return this.clampPoint(t,gn).distanceTo(t)}getBoundingSphere(t){return this.isEmpty()?t.makeEmpty():(this.getCenter(t.center),t.radius=this.getSize(gn).length()*.5),t}intersect(t){return this.min.max(t.min),this.max.min(t.max),this.isEmpty()&&this.makeEmpty(),this}union(t){return this.min.min(t.min),this.max.max(t.max),this}applyMatrix4(t){return this.isEmpty()?this:(On[0].set(this.min.x,this.min.y,this.min.z).applyMatrix4(t),On[1].set(this.min.x,this.min.y,this.max.z).applyMatrix4(t),On[2].set(this.min.x,this.max.y,this.min.z).applyMatrix4(t),On[3].set(this.min.x,this.max.y,this.max.z).applyMatrix4(t),On[4].set(this.max.x,this.min.y,this.min.z).applyMatrix4(t),On[5].set(this.max.x,this.min.y,this.max.z).applyMatrix4(t),On[6].set(this.max.x,this.max.y,this.min.z).applyMatrix4(t),On[7].set(this.max.x,this.max.y,this.max.z).applyMatrix4(t),this.setFromPoints(On),this)}translate(t){return this.min.add(t),this.max.add(t),this}equals(t){return t.min.equals(this.min)&&t.max.equals(this.max)}}const On=[new P,new P,new P,new P,new P,new P,new P,new P],gn=new P,cr=new Qn,zi=new P,Hi=new P,Vi=new P,ni=new P,ii=new P,Mi=new P,As=new P,hr=new P,ur=new P,bi=new P;function va(r,t,e,n,i){for(let s=0,a=r.length-3;s<=a;s+=3){bi.fromArray(r,s);const o=i.x*Math.abs(bi.x)+i.y*Math.abs(bi.y)+i.z*Math.abs(bi.z),l=t.dot(bi),c=e.dot(bi),h=n.dot(bi);if(Math.max(-Math.max(l,c,h),Math.min(l,c,h))>o)return!1}return!0}const af=new Qn,Rs=new P,_a=new P;class Ln{constructor(t=new P,e=-1){this.isSphere=!0,this.center=t,this.radius=e}set(t,e){return this.center.copy(t),this.radius=e,this}setFromPoints(t,e){const n=this.center;e!==void 0?n.copy(e):af.setFromPoints(t).getCenter(n);let i=0;for(let s=0,a=t.length;s<a;s++)i=Math.max(i,n.distanceToSquared(t[s]));return this.radius=Math.sqrt(i),this}copy(t){return this.center.copy(t.center),this.radius=t.radius,this}isEmpty(){return this.radius<0}makeEmpty(){return this.center.set(0,0,0),this.radius=-1,this}containsPoint(t){return t.distanceToSquared(this.center)<=this.radius*this.radius}distanceToPoint(t){return t.distanceTo(this.center)-this.radius}intersectsSphere(t){const e=this.radius+t.radius;return t.center.distanceToSquared(this.center)<=e*e}intersectsBox(t){return t.intersectsSphere(this)}intersectsPlane(t){return Math.abs(t.distanceToPoint(this.center))<=this.radius}clampPoint(t,e){const n=this.center.distanceToSquared(t);return e.copy(t),n>this.radius*this.radius&&(e.sub(this.center).normalize(),e.multiplyScalar(this.radius).add(this.center)),e}getBoundingBox(t){return this.isEmpty()?(t.makeEmpty(),t):(t.set(this.center,this.center),t.expandByScalar(this.radius),t)}applyMatrix4(t){return this.center.applyMatrix4(t),this.radius=this.radius*t.getMaxScaleOnAxis(),this}translate(t){return this.center.add(t),this}expandByPoint(t){if(this.isEmpty())return this.center.copy(t),this.radius=0,this;Rs.subVectors(t,this.center);const e=Rs.lengthSq();if(e>this.radius*this.radius){const n=Math.sqrt(e),i=(n-this.radius)*.5;this.center.addScaledVector(Rs,i/n),this.radius+=i}return this}union(t){return t.isEmpty()?this:this.isEmpty()?(this.copy(t),this):(this.center.equals(t.center)===!0?this.radius=Math.max(this.radius,t.radius):(_a.subVectors(t.center,this.center).setLength(t.radius),this.expandByPoint(Rs.copy(t.center).add(_a)),this.expandByPoint(Rs.copy(t.center).sub(_a))),this)}equals(t){return t.center.equals(this.center)&&t.radius===this.radius}clone(){return new this.constructor().copy(this)}}const kn=new P,xa=new P,dr=new P,si=new P,ya=new P,fr=new P,Ma=new P;class ra{constructor(t=new P,e=new P(0,0,-1)){this.origin=t,this.direction=e}set(t,e){return this.origin.copy(t),this.direction.copy(e),this}copy(t){return this.origin.copy(t.origin),this.direction.copy(t.direction),this}at(t,e){return e.copy(this.origin).addScaledVector(this.direction,t)}lookAt(t){return this.direction.copy(t).sub(this.origin).normalize(),this}recast(t){return this.origin.copy(this.at(t,kn)),this}closestPointToPoint(t,e){e.subVectors(t,this.origin);const n=e.dot(this.direction);return n<0?e.copy(this.origin):e.copy(this.origin).addScaledVector(this.direction,n)}distanceToPoint(t){return Math.sqrt(this.distanceSqToPoint(t))}distanceSqToPoint(t){const e=kn.subVectors(t,this.origin).dot(this.direction);return e<0?this.origin.distanceToSquared(t):(kn.copy(this.origin).addScaledVector(this.direction,e),kn.distanceToSquared(t))}distanceSqToSegment(t,e,n,i){xa.copy(t).add(e).multiplyScalar(.5),dr.copy(e).sub(t).normalize(),si.copy(this.origin).sub(xa);const s=t.distanceTo(e)*.5,a=-this.direction.dot(dr),o=si.dot(this.direction),l=-si.dot(dr),c=si.lengthSq(),h=Math.abs(1-a*a);let u,d,f,m;if(h>0)if(u=a*l-o,d=a*o-l,m=s*h,u>=0)if(d>=-m)if(d<=m){const v=1/h;u*=v,d*=v,f=u*(u+a*d+2*o)+d*(a*u+d+2*l)+c}else d=s,u=Math.max(0,-(a*d+o)),f=-u*u+d*(d+2*l)+c;else d=-s,u=Math.max(0,-(a*d+o)),f=-u*u+d*(d+2*l)+c;else d<=-m?(u=Math.max(0,-(-a*s+o)),d=u>0?-s:Math.min(Math.max(-s,-l),s),f=-u*u+d*(d+2*l)+c):d<=m?(u=0,d=Math.min(Math.max(-s,-l),s),f=d*(d+2*l)+c):(u=Math.max(0,-(a*s+o)),d=u>0?s:Math.min(Math.max(-s,-l),s),f=-u*u+d*(d+2*l)+c);else d=a>0?-s:s,u=Math.max(0,-(a*d+o)),f=-u*u+d*(d+2*l)+c;return n&&n.copy(this.origin).addScaledVector(this.direction,u),i&&i.copy(xa).addScaledVector(dr,d),f}intersectSphere(t,e){kn.subVectors(t.center,this.origin);const n=kn.dot(this.direction),i=kn.dot(kn)-n*n,s=t.radius*t.radius;if(i>s)return null;const a=Math.sqrt(s-i),o=n-a,l=n+a;return l<0?null:o<0?this.at(l,e):this.at(o,e)}intersectsSphere(t){return this.distanceSqToPoint(t.center)<=t.radius*t.radius}distanceToPlane(t){const e=t.normal.dot(this.direction);if(e===0)return t.distanceToPoint(this.origin)===0?0:null;const n=-(this.origin.dot(t.normal)+t.constant)/e;return n>=0?n:null}intersectPlane(t,e){const n=this.distanceToPlane(t);return n===null?null:this.at(n,e)}intersectsPlane(t){const e=t.distanceToPoint(this.origin);return e===0||t.normal.dot(this.direction)*e<0}intersectBox(t,e){let n,i,s,a,o,l;const c=1/this.direction.x,h=1/this.direction.y,u=1/this.direction.z,d=this.origin;return c>=0?(n=(t.min.x-d.x)*c,i=(t.max.x-d.x)*c):(n=(t.max.x-d.x)*c,i=(t.min.x-d.x)*c),h>=0?(s=(t.min.y-d.y)*h,a=(t.max.y-d.y)*h):(s=(t.max.y-d.y)*h,a=(t.min.y-d.y)*h),n>a||s>i||((s>n||isNaN(n))&&(n=s),(a<i||isNaN(i))&&(i=a),u>=0?(o=(t.min.z-d.z)*u,l=(t.max.z-d.z)*u):(o=(t.max.z-d.z)*u,l=(t.min.z-d.z)*u),n>l||o>i)||((o>n||n!==n)&&(n=o),(l<i||i!==i)&&(i=l),i<0)?null:this.at(n>=0?n:i,e)}intersectsBox(t){return this.intersectBox(t,kn)!==null}intersectTriangle(t,e,n,i,s){ya.subVectors(e,t),fr.subVectors(n,t),Ma.crossVectors(ya,fr);let a=this.direction.dot(Ma),o;if(a>0){if(i)return null;o=1}else if(a<0)o=-1,a=-a;else return null;si.subVectors(this.origin,t);const l=o*this.direction.dot(fr.crossVectors(si,fr));if(l<0)return null;const c=o*this.direction.dot(ya.cross(si));if(c<0||l+c>a)return null;const h=-o*si.dot(Ma);return h<0?null:this.at(h/a,s)}applyMatrix4(t){return this.origin.applyMatrix4(t),this.direction.transformDirection(t),this}equals(t){return t.origin.equals(this.origin)&&t.direction.equals(this.direction)}clone(){return new this.constructor().copy(this)}}class It{constructor(t,e,n,i,s,a,o,l,c,h,u,d,f,m,v,g){It.prototype.isMatrix4=!0,this.elements=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1],t!==void 0&&this.set(t,e,n,i,s,a,o,l,c,h,u,d,f,m,v,g)}set(t,e,n,i,s,a,o,l,c,h,u,d,f,m,v,g){const p=this.elements;return p[0]=t,p[4]=e,p[8]=n,p[12]=i,p[1]=s,p[5]=a,p[9]=o,p[13]=l,p[2]=c,p[6]=h,p[10]=u,p[14]=d,p[3]=f,p[7]=m,p[11]=v,p[15]=g,this}identity(){return this.set(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1),this}clone(){return new It().fromArray(this.elements)}copy(t){const e=this.elements,n=t.elements;return e[0]=n[0],e[1]=n[1],e[2]=n[2],e[3]=n[3],e[4]=n[4],e[5]=n[5],e[6]=n[6],e[7]=n[7],e[8]=n[8],e[9]=n[9],e[10]=n[10],e[11]=n[11],e[12]=n[12],e[13]=n[13],e[14]=n[14],e[15]=n[15],this}copyPosition(t){const e=this.elements,n=t.elements;return e[12]=n[12],e[13]=n[13],e[14]=n[14],this}setFromMatrix3(t){const e=t.elements;return this.set(e[0],e[3],e[6],0,e[1],e[4],e[7],0,e[2],e[5],e[8],0,0,0,0,1),this}extractBasis(t,e,n){return t.setFromMatrixColumn(this,0),e.setFromMatrixColumn(this,1),n.setFromMatrixColumn(this,2),this}makeBasis(t,e,n){return this.set(t.x,e.x,n.x,0,t.y,e.y,n.y,0,t.z,e.z,n.z,0,0,0,0,1),this}extractRotation(t){const e=this.elements,n=t.elements,i=1/Gi.setFromMatrixColumn(t,0).length(),s=1/Gi.setFromMatrixColumn(t,1).length(),a=1/Gi.setFromMatrixColumn(t,2).length();return e[0]=n[0]*i,e[1]=n[1]*i,e[2]=n[2]*i,e[3]=0,e[4]=n[4]*s,e[5]=n[5]*s,e[6]=n[6]*s,e[7]=0,e[8]=n[8]*a,e[9]=n[9]*a,e[10]=n[10]*a,e[11]=0,e[12]=0,e[13]=0,e[14]=0,e[15]=1,this}makeRotationFromEuler(t){const e=this.elements,n=t.x,i=t.y,s=t.z,a=Math.cos(n),o=Math.sin(n),l=Math.cos(i),c=Math.sin(i),h=Math.cos(s),u=Math.sin(s);if(t.order==="XYZ"){const d=a*h,f=a*u,m=o*h,v=o*u;e[0]=l*h,e[4]=-l*u,e[8]=c,e[1]=f+m*c,e[5]=d-v*c,e[9]=-o*l,e[2]=v-d*c,e[6]=m+f*c,e[10]=a*l}else if(t.order==="YXZ"){const d=l*h,f=l*u,m=c*h,v=c*u;e[0]=d+v*o,e[4]=m*o-f,e[8]=a*c,e[1]=a*u,e[5]=a*h,e[9]=-o,e[2]=f*o-m,e[6]=v+d*o,e[10]=a*l}else if(t.order==="ZXY"){const d=l*h,f=l*u,m=c*h,v=c*u;e[0]=d-v*o,e[4]=-a*u,e[8]=m+f*o,e[1]=f+m*o,e[5]=a*h,e[9]=v-d*o,e[2]=-a*c,e[6]=o,e[10]=a*l}else if(t.order==="ZYX"){const d=a*h,f=a*u,m=o*h,v=o*u;e[0]=l*h,e[4]=m*c-f,e[8]=d*c+v,e[1]=l*u,e[5]=v*c+d,e[9]=f*c-m,e[2]=-c,e[6]=o*l,e[10]=a*l}else if(t.order==="YZX"){const d=a*l,f=a*c,m=o*l,v=o*c;e[0]=l*h,e[4]=v-d*u,e[8]=m*u+f,e[1]=u,e[5]=a*h,e[9]=-o*h,e[2]=-c*h,e[6]=f*u+m,e[10]=d-v*u}else if(t.order==="XZY"){const d=a*l,f=a*c,m=o*l,v=o*c;e[0]=l*h,e[4]=-u,e[8]=c*h,e[1]=d*u+v,e[5]=a*h,e[9]=f*u-m,e[2]=m*u-f,e[6]=o*h,e[10]=v*u+d}return e[3]=0,e[7]=0,e[11]=0,e[12]=0,e[13]=0,e[14]=0,e[15]=1,this}makeRotationFromQuaternion(t){return this.compose(of,t,lf)}lookAt(t,e,n){const i=this.elements;return Ze.subVectors(t,e),Ze.lengthSq()===0&&(Ze.z=1),Ze.normalize(),ri.crossVectors(n,Ze),ri.lengthSq()===0&&(Math.abs(n.z)===1?Ze.x+=1e-4:Ze.z+=1e-4,Ze.normalize(),ri.crossVectors(n,Ze)),ri.normalize(),pr.crossVectors(Ze,ri),i[0]=ri.x,i[4]=pr.x,i[8]=Ze.x,i[1]=ri.y,i[5]=pr.y,i[9]=Ze.y,i[2]=ri.z,i[6]=pr.z,i[10]=Ze.z,this}multiply(t){return this.multiplyMatrices(this,t)}premultiply(t){return this.multiplyMatrices(t,this)}multiplyMatrices(t,e){const n=t.elements,i=e.elements,s=this.elements,a=n[0],o=n[4],l=n[8],c=n[12],h=n[1],u=n[5],d=n[9],f=n[13],m=n[2],v=n[6],g=n[10],p=n[14],x=n[3],y=n[7],_=n[11],I=n[15],E=i[0],A=i[4],C=i[8],b=i[12],M=i[1],L=i[5],z=i[9],R=i[13],B=i[2],j=i[6],X=i[10],Q=i[14],G=i[3],it=i[7],lt=i[11],St=i[15];return s[0]=a*E+o*M+l*B+c*G,s[4]=a*A+o*L+l*j+c*it,s[8]=a*C+o*z+l*X+c*lt,s[12]=a*b+o*R+l*Q+c*St,s[1]=h*E+u*M+d*B+f*G,s[5]=h*A+u*L+d*j+f*it,s[9]=h*C+u*z+d*X+f*lt,s[13]=h*b+u*R+d*Q+f*St,s[2]=m*E+v*M+g*B+p*G,s[6]=m*A+v*L+g*j+p*it,s[10]=m*C+v*z+g*X+p*lt,s[14]=m*b+v*R+g*Q+p*St,s[3]=x*E+y*M+_*B+I*G,s[7]=x*A+y*L+_*j+I*it,s[11]=x*C+y*z+_*X+I*lt,s[15]=x*b+y*R+_*Q+I*St,this}multiplyScalar(t){const e=this.elements;return e[0]*=t,e[4]*=t,e[8]*=t,e[12]*=t,e[1]*=t,e[5]*=t,e[9]*=t,e[13]*=t,e[2]*=t,e[6]*=t,e[10]*=t,e[14]*=t,e[3]*=t,e[7]*=t,e[11]*=t,e[15]*=t,this}determinant(){const t=this.elements,e=t[0],n=t[4],i=t[8],s=t[12],a=t[1],o=t[5],l=t[9],c=t[13],h=t[2],u=t[6],d=t[10],f=t[14],m=t[3],v=t[7],g=t[11],p=t[15];return m*(+s*l*u-i*c*u-s*o*d+n*c*d+i*o*f-n*l*f)+v*(+e*l*f-e*c*d+s*a*d-i*a*f+i*c*h-s*l*h)+g*(+e*c*u-e*o*f-s*a*u+n*a*f+s*o*h-n*c*h)+p*(-i*o*h-e*l*u+e*o*d+i*a*u-n*a*d+n*l*h)}transpose(){const t=this.elements;let e;return e=t[1],t[1]=t[4],t[4]=e,e=t[2],t[2]=t[8],t[8]=e,e=t[6],t[6]=t[9],t[9]=e,e=t[3],t[3]=t[12],t[12]=e,e=t[7],t[7]=t[13],t[13]=e,e=t[11],t[11]=t[14],t[14]=e,this}setPosition(t,e,n){const i=this.elements;return t.isVector3?(i[12]=t.x,i[13]=t.y,i[14]=t.z):(i[12]=t,i[13]=e,i[14]=n),this}invert(){const t=this.elements,e=t[0],n=t[1],i=t[2],s=t[3],a=t[4],o=t[5],l=t[6],c=t[7],h=t[8],u=t[9],d=t[10],f=t[11],m=t[12],v=t[13],g=t[14],p=t[15],x=u*g*c-v*d*c+v*l*f-o*g*f-u*l*p+o*d*p,y=m*d*c-h*g*c-m*l*f+a*g*f+h*l*p-a*d*p,_=h*v*c-m*u*c+m*o*f-a*v*f-h*o*p+a*u*p,I=m*u*l-h*v*l-m*o*d+a*v*d+h*o*g-a*u*g,E=e*x+n*y+i*_+s*I;if(E===0)return this.set(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);const A=1/E;return t[0]=x*A,t[1]=(v*d*s-u*g*s-v*i*f+n*g*f+u*i*p-n*d*p)*A,t[2]=(o*g*s-v*l*s+v*i*c-n*g*c-o*i*p+n*l*p)*A,t[3]=(u*l*s-o*d*s-u*i*c+n*d*c+o*i*f-n*l*f)*A,t[4]=y*A,t[5]=(h*g*s-m*d*s+m*i*f-e*g*f-h*i*p+e*d*p)*A,t[6]=(m*l*s-a*g*s-m*i*c+e*g*c+a*i*p-e*l*p)*A,t[7]=(a*d*s-h*l*s+h*i*c-e*d*c-a*i*f+e*l*f)*A,t[8]=_*A,t[9]=(m*u*s-h*v*s-m*n*f+e*v*f+h*n*p-e*u*p)*A,t[10]=(a*v*s-m*o*s+m*n*c-e*v*c-a*n*p+e*o*p)*A,t[11]=(h*o*s-a*u*s-h*n*c+e*u*c+a*n*f-e*o*f)*A,t[12]=I*A,t[13]=(h*v*i-m*u*i+m*n*d-e*v*d-h*n*g+e*u*g)*A,t[14]=(m*o*i-a*v*i-m*n*l+e*v*l+a*n*g-e*o*g)*A,t[15]=(a*u*i-h*o*i+h*n*l-e*u*l-a*n*d+e*o*d)*A,this}scale(t){const e=this.elements,n=t.x,i=t.y,s=t.z;return e[0]*=n,e[4]*=i,e[8]*=s,e[1]*=n,e[5]*=i,e[9]*=s,e[2]*=n,e[6]*=i,e[10]*=s,e[3]*=n,e[7]*=i,e[11]*=s,this}getMaxScaleOnAxis(){const t=this.elements,e=t[0]*t[0]+t[1]*t[1]+t[2]*t[2],n=t[4]*t[4]+t[5]*t[5]+t[6]*t[6],i=t[8]*t[8]+t[9]*t[9]+t[10]*t[10];return Math.sqrt(Math.max(e,n,i))}makeTranslation(t,e,n){return t.isVector3?this.set(1,0,0,t.x,0,1,0,t.y,0,0,1,t.z,0,0,0,1):this.set(1,0,0,t,0,1,0,e,0,0,1,n,0,0,0,1),this}makeRotationX(t){const e=Math.cos(t),n=Math.sin(t);return this.set(1,0,0,0,0,e,-n,0,0,n,e,0,0,0,0,1),this}makeRotationY(t){const e=Math.cos(t),n=Math.sin(t);return this.set(e,0,n,0,0,1,0,0,-n,0,e,0,0,0,0,1),this}makeRotationZ(t){const e=Math.cos(t),n=Math.sin(t);return this.set(e,-n,0,0,n,e,0,0,0,0,1,0,0,0,0,1),this}makeRotationAxis(t,e){const n=Math.cos(e),i=Math.sin(e),s=1-n,a=t.x,o=t.y,l=t.z,c=s*a,h=s*o;return this.set(c*a+n,c*o-i*l,c*l+i*o,0,c*o+i*l,h*o+n,h*l-i*a,0,c*l-i*o,h*l+i*a,s*l*l+n,0,0,0,0,1),this}makeScale(t,e,n){return this.set(t,0,0,0,0,e,0,0,0,0,n,0,0,0,0,1),this}makeShear(t,e,n,i,s,a){return this.set(1,n,s,0,t,1,a,0,e,i,1,0,0,0,0,1),this}compose(t,e,n){const i=this.elements,s=e._x,a=e._y,o=e._z,l=e._w,c=s+s,h=a+a,u=o+o,d=s*c,f=s*h,m=s*u,v=a*h,g=a*u,p=o*u,x=l*c,y=l*h,_=l*u,I=n.x,E=n.y,A=n.z;return i[0]=(1-(v+p))*I,i[1]=(f+_)*I,i[2]=(m-y)*I,i[3]=0,i[4]=(f-_)*E,i[5]=(1-(d+p))*E,i[6]=(g+x)*E,i[7]=0,i[8]=(m+y)*A,i[9]=(g-x)*A,i[10]=(1-(d+v))*A,i[11]=0,i[12]=t.x,i[13]=t.y,i[14]=t.z,i[15]=1,this}decompose(t,e,n){const i=this.elements;let s=Gi.set(i[0],i[1],i[2]).length();const a=Gi.set(i[4],i[5],i[6]).length(),o=Gi.set(i[8],i[9],i[10]).length();this.determinant()<0&&(s=-s),t.x=i[12],t.y=i[13],t.z=i[14],vn.copy(this);const c=1/s,h=1/a,u=1/o;return vn.elements[0]*=c,vn.elements[1]*=c,vn.elements[2]*=c,vn.elements[4]*=h,vn.elements[5]*=h,vn.elements[6]*=h,vn.elements[8]*=u,vn.elements[9]*=u,vn.elements[10]*=u,e.setFromRotationMatrix(vn),n.x=s,n.y=a,n.z=o,this}makePerspective(t,e,n,i,s,a,o=Kn){const l=this.elements,c=2*s/(e-t),h=2*s/(n-i),u=(e+t)/(e-t),d=(n+i)/(n-i);let f,m;if(o===Kn)f=-(a+s)/(a-s),m=-2*a*s/(a-s);else if(o===jr)f=-a/(a-s),m=-a*s/(a-s);else throw new Error("THREE.Matrix4.makePerspective(): Invalid coordinate system: "+o);return l[0]=c,l[4]=0,l[8]=u,l[12]=0,l[1]=0,l[5]=h,l[9]=d,l[13]=0,l[2]=0,l[6]=0,l[10]=f,l[14]=m,l[3]=0,l[7]=0,l[11]=-1,l[15]=0,this}makeOrthographic(t,e,n,i,s,a,o=Kn){const l=this.elements,c=1/(e-t),h=1/(n-i),u=1/(a-s),d=(e+t)*c,f=(n+i)*h;let m,v;if(o===Kn)m=(a+s)*u,v=-2*u;else if(o===jr)m=s*u,v=-1*u;else throw new Error("THREE.Matrix4.makeOrthographic(): Invalid coordinate system: "+o);return l[0]=2*c,l[4]=0,l[8]=0,l[12]=-d,l[1]=0,l[5]=2*h,l[9]=0,l[13]=-f,l[2]=0,l[6]=0,l[10]=v,l[14]=-m,l[3]=0,l[7]=0,l[11]=0,l[15]=1,this}equals(t){const e=this.elements,n=t.elements;for(let i=0;i<16;i++)if(e[i]!==n[i])return!1;return!0}fromArray(t,e=0){for(let n=0;n<16;n++)this.elements[n]=t[n+e];return this}toArray(t=[],e=0){const n=this.elements;return t[e]=n[0],t[e+1]=n[1],t[e+2]=n[2],t[e+3]=n[3],t[e+4]=n[4],t[e+5]=n[5],t[e+6]=n[6],t[e+7]=n[7],t[e+8]=n[8],t[e+9]=n[9],t[e+10]=n[10],t[e+11]=n[11],t[e+12]=n[12],t[e+13]=n[13],t[e+14]=n[14],t[e+15]=n[15],t}}const Gi=new P,vn=new It,of=new P(0,0,0),lf=new P(1,1,1),ri=new P,pr=new P,Ze=new P,ec=new It,nc=new xi;class En{constructor(t=0,e=0,n=0,i=En.DEFAULT_ORDER){this.isEuler=!0,this._x=t,this._y=e,this._z=n,this._order=i}get x(){return this._x}set x(t){this._x=t,this._onChangeCallback()}get y(){return this._y}set y(t){this._y=t,this._onChangeCallback()}get z(){return this._z}set z(t){this._z=t,this._onChangeCallback()}get order(){return this._order}set order(t){this._order=t,this._onChangeCallback()}set(t,e,n,i=this._order){return this._x=t,this._y=e,this._z=n,this._order=i,this._onChangeCallback(),this}clone(){return new this.constructor(this._x,this._y,this._z,this._order)}copy(t){return this._x=t._x,this._y=t._y,this._z=t._z,this._order=t._order,this._onChangeCallback(),this}setFromRotationMatrix(t,e=this._order,n=!0){const i=t.elements,s=i[0],a=i[4],o=i[8],l=i[1],c=i[5],h=i[9],u=i[2],d=i[6],f=i[10];switch(e){case"XYZ":this._y=Math.asin(Ae(o,-1,1)),Math.abs(o)<.9999999?(this._x=Math.atan2(-h,f),this._z=Math.atan2(-a,s)):(this._x=Math.atan2(d,c),this._z=0);break;case"YXZ":this._x=Math.asin(-Ae(h,-1,1)),Math.abs(h)<.9999999?(this._y=Math.atan2(o,f),this._z=Math.atan2(l,c)):(this._y=Math.atan2(-u,s),this._z=0);break;case"ZXY":this._x=Math.asin(Ae(d,-1,1)),Math.abs(d)<.9999999?(this._y=Math.atan2(-u,f),this._z=Math.atan2(-a,c)):(this._y=0,this._z=Math.atan2(l,s));break;case"ZYX":this._y=Math.asin(-Ae(u,-1,1)),Math.abs(u)<.9999999?(this._x=Math.atan2(d,f),this._z=Math.atan2(l,s)):(this._x=0,this._z=Math.atan2(-a,c));break;case"YZX":this._z=Math.asin(Ae(l,-1,1)),Math.abs(l)<.9999999?(this._x=Math.atan2(-h,c),this._y=Math.atan2(-u,s)):(this._x=0,this._y=Math.atan2(o,f));break;case"XZY":this._z=Math.asin(-Ae(a,-1,1)),Math.abs(a)<.9999999?(this._x=Math.atan2(d,c),this._y=Math.atan2(o,s)):(this._x=Math.atan2(-h,f),this._y=0);break;default:console.warn("THREE.Euler: .setFromRotationMatrix() encountered an unknown order: "+e)}return this._order=e,n===!0&&this._onChangeCallback(),this}setFromQuaternion(t,e,n){return ec.makeRotationFromQuaternion(t),this.setFromRotationMatrix(ec,e,n)}setFromVector3(t,e=this._order){return this.set(t.x,t.y,t.z,e)}reorder(t){return nc.setFromEuler(this),this.setFromQuaternion(nc,t)}equals(t){return t._x===this._x&&t._y===this._y&&t._z===this._z&&t._order===this._order}fromArray(t){return this._x=t[0],this._y=t[1],this._z=t[2],t[3]!==void 0&&(this._order=t[3]),this._onChangeCallback(),this}toArray(t=[],e=0){return t[e]=this._x,t[e+1]=this._y,t[e+2]=this._z,t[e+3]=this._order,t}_onChange(t){return this._onChangeCallback=t,this}_onChangeCallback(){}*[Symbol.iterator](){yield this._x,yield this._y,yield this._z,yield this._order}}En.DEFAULT_ORDER="XYZ";class tu{constructor(){this.mask=1}set(t){this.mask=(1<<t|0)>>>0}enable(t){this.mask|=1<<t|0}enableAll(){this.mask=-1}toggle(t){this.mask^=1<<t|0}disable(t){this.mask&=~(1<<t|0)}disableAll(){this.mask=0}test(t){return(this.mask&t.mask)!==0}isEnabled(t){return(this.mask&(1<<t|0))!==0}}let cf=0;const ic=new P,Wi=new xi,Bn=new It,mr=new P,Cs=new P,hf=new P,uf=new xi,sc=new P(1,0,0),rc=new P(0,1,0),ac=new P(0,0,1),oc={type:"added"},df={type:"removed"},Xi={type:"childadded",child:null},ba={type:"childremoved",child:null};class he extends _s{constructor(){super(),this.isObject3D=!0,Object.defineProperty(this,"id",{value:cf++}),this.uuid=wn(),this.name="",this.type="Object3D",this.parent=null,this.children=[],this.up=he.DEFAULT_UP.clone();const t=new P,e=new En,n=new xi,i=new P(1,1,1);function s(){n.setFromEuler(e,!1)}function a(){e.setFromQuaternion(n,void 0,!1)}e._onChange(s),n._onChange(a),Object.defineProperties(this,{position:{configurable:!0,enumerable:!0,value:t},rotation:{configurable:!0,enumerable:!0,value:e},quaternion:{configurable:!0,enumerable:!0,value:n},scale:{configurable:!0,enumerable:!0,value:i},modelViewMatrix:{value:new It},normalMatrix:{value:new Ut}}),this.matrix=new It,this.matrixWorld=new It,this.matrixAutoUpdate=he.DEFAULT_MATRIX_AUTO_UPDATE,this.matrixWorldAutoUpdate=he.DEFAULT_MATRIX_WORLD_AUTO_UPDATE,this.matrixWorldNeedsUpdate=!1,this.layers=new tu,this.visible=!0,this.castShadow=!1,this.receiveShadow=!1,this.frustumCulled=!0,this.renderOrder=0,this.animations=[],this.userData={}}onBeforeShadow(){}onAfterShadow(){}onBeforeRender(){}onAfterRender(){}applyMatrix4(t){this.matrixAutoUpdate&&this.updateMatrix(),this.matrix.premultiply(t),this.matrix.decompose(this.position,this.quaternion,this.scale)}applyQuaternion(t){return this.quaternion.premultiply(t),this}setRotationFromAxisAngle(t,e){this.quaternion.setFromAxisAngle(t,e)}setRotationFromEuler(t){this.quaternion.setFromEuler(t,!0)}setRotationFromMatrix(t){this.quaternion.setFromRotationMatrix(t)}setRotationFromQuaternion(t){this.quaternion.copy(t)}rotateOnAxis(t,e){return Wi.setFromAxisAngle(t,e),this.quaternion.multiply(Wi),this}rotateOnWorldAxis(t,e){return Wi.setFromAxisAngle(t,e),this.quaternion.premultiply(Wi),this}rotateX(t){return this.rotateOnAxis(sc,t)}rotateY(t){return this.rotateOnAxis(rc,t)}rotateZ(t){return this.rotateOnAxis(ac,t)}translateOnAxis(t,e){return ic.copy(t).applyQuaternion(this.quaternion),this.position.add(ic.multiplyScalar(e)),this}translateX(t){return this.translateOnAxis(sc,t)}translateY(t){return this.translateOnAxis(rc,t)}translateZ(t){return this.translateOnAxis(ac,t)}localToWorld(t){return this.updateWorldMatrix(!0,!1),t.applyMatrix4(this.matrixWorld)}worldToLocal(t){return this.updateWorldMatrix(!0,!1),t.applyMatrix4(Bn.copy(this.matrixWorld).invert())}lookAt(t,e,n){t.isVector3?mr.copy(t):mr.set(t,e,n);const i=this.parent;this.updateWorldMatrix(!0,!1),Cs.setFromMatrixPosition(this.matrixWorld),this.isCamera||this.isLight?Bn.lookAt(Cs,mr,this.up):Bn.lookAt(mr,Cs,this.up),this.quaternion.setFromRotationMatrix(Bn),i&&(Bn.extractRotation(i.matrixWorld),Wi.setFromRotationMatrix(Bn),this.quaternion.premultiply(Wi.invert()))}add(t){if(arguments.length>1){for(let e=0;e<arguments.length;e++)this.add(arguments[e]);return this}return t===this?(console.error("THREE.Object3D.add: object can't be added as a child of itself.",t),this):(t&&t.isObject3D?(t.removeFromParent(),t.parent=this,this.children.push(t),t.dispatchEvent(oc),Xi.child=t,this.dispatchEvent(Xi),Xi.child=null):console.error("THREE.Object3D.add: object not an instance of THREE.Object3D.",t),this)}remove(t){if(arguments.length>1){for(let n=0;n<arguments.length;n++)this.remove(arguments[n]);return this}const e=this.children.indexOf(t);return e!==-1&&(t.parent=null,this.children.splice(e,1),t.dispatchEvent(df),ba.child=t,this.dispatchEvent(ba),ba.child=null),this}removeFromParent(){const t=this.parent;return t!==null&&t.remove(this),this}clear(){return this.remove(...this.children)}attach(t){return this.updateWorldMatrix(!0,!1),Bn.copy(this.matrixWorld).invert(),t.parent!==null&&(t.parent.updateWorldMatrix(!0,!1),Bn.multiply(t.parent.matrixWorld)),t.applyMatrix4(Bn),t.removeFromParent(),t.parent=this,this.children.push(t),t.updateWorldMatrix(!1,!0),t.dispatchEvent(oc),Xi.child=t,this.dispatchEvent(Xi),Xi.child=null,this}getObjectById(t){return this.getObjectByProperty("id",t)}getObjectByName(t){return this.getObjectByProperty("name",t)}getObjectByProperty(t,e){if(this[t]===e)return this;for(let n=0,i=this.children.length;n<i;n++){const a=this.children[n].getObjectByProperty(t,e);if(a!==void 0)return a}}getObjectsByProperty(t,e,n=[]){this[t]===e&&n.push(this);const i=this.children;for(let s=0,a=i.length;s<a;s++)i[s].getObjectsByProperty(t,e,n);return n}getWorldPosition(t){return this.updateWorldMatrix(!0,!1),t.setFromMatrixPosition(this.matrixWorld)}getWorldQuaternion(t){return this.updateWorldMatrix(!0,!1),this.matrixWorld.decompose(Cs,t,hf),t}getWorldScale(t){return this.updateWorldMatrix(!0,!1),this.matrixWorld.decompose(Cs,uf,t),t}getWorldDirection(t){this.updateWorldMatrix(!0,!1);const e=this.matrixWorld.elements;return t.set(e[8],e[9],e[10]).normalize()}raycast(){}traverse(t){t(this);const e=this.children;for(let n=0,i=e.length;n<i;n++)e[n].traverse(t)}traverseVisible(t){if(this.visible===!1)return;t(this);const e=this.children;for(let n=0,i=e.length;n<i;n++)e[n].traverseVisible(t)}traverseAncestors(t){const e=this.parent;e!==null&&(t(e),e.traverseAncestors(t))}updateMatrix(){this.matrix.compose(this.position,this.quaternion,this.scale),this.matrixWorldNeedsUpdate=!0}updateMatrixWorld(t){this.matrixAutoUpdate&&this.updateMatrix(),(this.matrixWorldNeedsUpdate||t)&&(this.matrixWorldAutoUpdate===!0&&(this.parent===null?this.matrixWorld.copy(this.matrix):this.matrixWorld.multiplyMatrices(this.parent.matrixWorld,this.matrix)),this.matrixWorldNeedsUpdate=!1,t=!0);const e=this.children;for(let n=0,i=e.length;n<i;n++)e[n].updateMatrixWorld(t)}updateWorldMatrix(t,e){const n=this.parent;if(t===!0&&n!==null&&n.updateWorldMatrix(!0,!1),this.matrixAutoUpdate&&this.updateMatrix(),this.matrixWorldAutoUpdate===!0&&(this.parent===null?this.matrixWorld.copy(this.matrix):this.matrixWorld.multiplyMatrices(this.parent.matrixWorld,this.matrix)),e===!0){const i=this.children;for(let s=0,a=i.length;s<a;s++)i[s].updateWorldMatrix(!1,!0)}}toJSON(t){const e=t===void 0||typeof t=="string",n={};e&&(t={geometries:{},materials:{},textures:{},images:{},shapes:{},skeletons:{},animations:{},nodes:{}},n.metadata={version:4.6,type:"Object",generator:"Object3D.toJSON"});const i={};i.uuid=this.uuid,i.type=this.type,this.name!==""&&(i.name=this.name),this.castShadow===!0&&(i.castShadow=!0),this.receiveShadow===!0&&(i.receiveShadow=!0),this.visible===!1&&(i.visible=!1),this.frustumCulled===!1&&(i.frustumCulled=!1),this.renderOrder!==0&&(i.renderOrder=this.renderOrder),Object.keys(this.userData).length>0&&(i.userData=this.userData),i.layers=this.layers.mask,i.matrix=this.matrix.toArray(),i.up=this.up.toArray(),this.matrixAutoUpdate===!1&&(i.matrixAutoUpdate=!1),this.isInstancedMesh&&(i.type="InstancedMesh",i.count=this.count,i.instanceMatrix=this.instanceMatrix.toJSON(),this.instanceColor!==null&&(i.instanceColor=this.instanceColor.toJSON())),this.isBatchedMesh&&(i.type="BatchedMesh",i.perObjectFrustumCulled=this.perObjectFrustumCulled,i.sortObjects=this.sortObjects,i.drawRanges=this._drawRanges,i.reservedRanges=this._reservedRanges,i.visibility=this._visibility,i.active=this._active,i.bounds=this._bounds.map(o=>({boxInitialized:o.boxInitialized,boxMin:o.box.min.toArray(),boxMax:o.box.max.toArray(),sphereInitialized:o.sphereInitialized,sphereRadius:o.sphere.radius,sphereCenter:o.sphere.center.toArray()})),i.maxInstanceCount=this._maxInstanceCount,i.maxVertexCount=this._maxVertexCount,i.maxIndexCount=this._maxIndexCount,i.geometryInitialized=this._geometryInitialized,i.geometryCount=this._geometryCount,i.matricesTexture=this._matricesTexture.toJSON(t),this._colorsTexture!==null&&(i.colorsTexture=this._colorsTexture.toJSON(t)),this.boundingSphere!==null&&(i.boundingSphere={center:i.boundingSphere.center.toArray(),radius:i.boundingSphere.radius}),this.boundingBox!==null&&(i.boundingBox={min:i.boundingBox.min.toArray(),max:i.boundingBox.max.toArray()}));function s(o,l){return o[l.uuid]===void 0&&(o[l.uuid]=l.toJSON(t)),l.uuid}if(this.isScene)this.background&&(this.background.isColor?i.background=this.background.toJSON():this.background.isTexture&&(i.background=this.background.toJSON(t).uuid)),this.environment&&this.environment.isTexture&&this.environment.isRenderTargetTexture!==!0&&(i.environment=this.environment.toJSON(t).uuid);else if(this.isMesh||this.isLine||this.isPoints){i.geometry=s(t.geometries,this.geometry);const o=this.geometry.parameters;if(o!==void 0&&o.shapes!==void 0){const l=o.shapes;if(Array.isArray(l))for(let c=0,h=l.length;c<h;c++){const u=l[c];s(t.shapes,u)}else s(t.shapes,l)}}if(this.isSkinnedMesh&&(i.bindMode=this.bindMode,i.bindMatrix=this.bindMatrix.toArray(),this.skeleton!==void 0&&(s(t.skeletons,this.skeleton),i.skeleton=this.skeleton.uuid)),this.material!==void 0)if(Array.isArray(this.material)){const o=[];for(let l=0,c=this.material.length;l<c;l++)o.push(s(t.materials,this.material[l]));i.material=o}else i.material=s(t.materials,this.material);if(this.children.length>0){i.children=[];for(let o=0;o<this.children.length;o++)i.children.push(this.children[o].toJSON(t).object)}if(this.animations.length>0){i.animations=[];for(let o=0;o<this.animations.length;o++){const l=this.animations[o];i.animations.push(s(t.animations,l))}}if(e){const o=a(t.geometries),l=a(t.materials),c=a(t.textures),h=a(t.images),u=a(t.shapes),d=a(t.skeletons),f=a(t.animations),m=a(t.nodes);o.length>0&&(n.geometries=o),l.length>0&&(n.materials=l),c.length>0&&(n.textures=c),h.length>0&&(n.images=h),u.length>0&&(n.shapes=u),d.length>0&&(n.skeletons=d),f.length>0&&(n.animations=f),m.length>0&&(n.nodes=m)}return n.object=i,n;function a(o){const l=[];for(const c in o){const h=o[c];delete h.metadata,l.push(h)}return l}}clone(t){return new this.constructor().copy(this,t)}copy(t,e=!0){if(this.name=t.name,this.up.copy(t.up),this.position.copy(t.position),this.rotation.order=t.rotation.order,this.quaternion.copy(t.quaternion),this.scale.copy(t.scale),this.matrix.copy(t.matrix),this.matrixWorld.copy(t.matrixWorld),this.matrixAutoUpdate=t.matrixAutoUpdate,this.matrixWorldAutoUpdate=t.matrixWorldAutoUpdate,this.matrixWorldNeedsUpdate=t.matrixWorldNeedsUpdate,this.layers.mask=t.layers.mask,this.visible=t.visible,this.castShadow=t.castShadow,this.receiveShadow=t.receiveShadow,this.frustumCulled=t.frustumCulled,this.renderOrder=t.renderOrder,this.animations=t.animations.slice(),this.userData=JSON.parse(JSON.stringify(t.userData)),e===!0)for(let n=0;n<t.children.length;n++){const i=t.children[n];this.add(i.clone())}return this}}he.DEFAULT_UP=new P(0,1,0);he.DEFAULT_MATRIX_AUTO_UPDATE=!0;he.DEFAULT_MATRIX_WORLD_AUTO_UPDATE=!0;const _n=new P,zn=new P,Sa=new P,Hn=new P,qi=new P,Yi=new P,lc=new P,wa=new P,Ta=new P,Ea=new P,Aa=new Qt,Ra=new Qt,Ca=new Qt;class bn{constructor(t=new P,e=new P,n=new P){this.a=t,this.b=e,this.c=n}static getNormal(t,e,n,i){i.subVectors(n,e),_n.subVectors(t,e),i.cross(_n);const s=i.lengthSq();return s>0?i.multiplyScalar(1/Math.sqrt(s)):i.set(0,0,0)}static getBarycoord(t,e,n,i,s){_n.subVectors(i,e),zn.subVectors(n,e),Sa.subVectors(t,e);const a=_n.dot(_n),o=_n.dot(zn),l=_n.dot(Sa),c=zn.dot(zn),h=zn.dot(Sa),u=a*c-o*o;if(u===0)return s.set(0,0,0),null;const d=1/u,f=(c*l-o*h)*d,m=(a*h-o*l)*d;return s.set(1-f-m,m,f)}static containsPoint(t,e,n,i){return this.getBarycoord(t,e,n,i,Hn)===null?!1:Hn.x>=0&&Hn.y>=0&&Hn.x+Hn.y<=1}static getInterpolation(t,e,n,i,s,a,o,l){return this.getBarycoord(t,e,n,i,Hn)===null?(l.x=0,l.y=0,"z"in l&&(l.z=0),"w"in l&&(l.w=0),null):(l.setScalar(0),l.addScaledVector(s,Hn.x),l.addScaledVector(a,Hn.y),l.addScaledVector(o,Hn.z),l)}static getInterpolatedAttribute(t,e,n,i,s,a){return Aa.setScalar(0),Ra.setScalar(0),Ca.setScalar(0),Aa.fromBufferAttribute(t,e),Ra.fromBufferAttribute(t,n),Ca.fromBufferAttribute(t,i),a.setScalar(0),a.addScaledVector(Aa,s.x),a.addScaledVector(Ra,s.y),a.addScaledVector(Ca,s.z),a}static isFrontFacing(t,e,n,i){return _n.subVectors(n,e),zn.subVectors(t,e),_n.cross(zn).dot(i)<0}set(t,e,n){return this.a.copy(t),this.b.copy(e),this.c.copy(n),this}setFromPointsAndIndices(t,e,n,i){return this.a.copy(t[e]),this.b.copy(t[n]),this.c.copy(t[i]),this}setFromAttributeAndIndices(t,e,n,i){return this.a.fromBufferAttribute(t,e),this.b.fromBufferAttribute(t,n),this.c.fromBufferAttribute(t,i),this}clone(){return new this.constructor().copy(this)}copy(t){return this.a.copy(t.a),this.b.copy(t.b),this.c.copy(t.c),this}getArea(){return _n.subVectors(this.c,this.b),zn.subVectors(this.a,this.b),_n.cross(zn).length()*.5}getMidpoint(t){return t.addVectors(this.a,this.b).add(this.c).multiplyScalar(1/3)}getNormal(t){return bn.getNormal(this.a,this.b,this.c,t)}getPlane(t){return t.setFromCoplanarPoints(this.a,this.b,this.c)}getBarycoord(t,e){return bn.getBarycoord(t,this.a,this.b,this.c,e)}getInterpolation(t,e,n,i,s){return bn.getInterpolation(t,this.a,this.b,this.c,e,n,i,s)}containsPoint(t){return bn.containsPoint(t,this.a,this.b,this.c)}isFrontFacing(t){return bn.isFrontFacing(this.a,this.b,this.c,t)}intersectsBox(t){return t.intersectsTriangle(this)}closestPointToPoint(t,e){const n=this.a,i=this.b,s=this.c;let a,o;qi.subVectors(i,n),Yi.subVectors(s,n),wa.subVectors(t,n);const l=qi.dot(wa),c=Yi.dot(wa);if(l<=0&&c<=0)return e.copy(n);Ta.subVectors(t,i);const h=qi.dot(Ta),u=Yi.dot(Ta);if(h>=0&&u<=h)return e.copy(i);const d=l*u-h*c;if(d<=0&&l>=0&&h<=0)return a=l/(l-h),e.copy(n).addScaledVector(qi,a);Ea.subVectors(t,s);const f=qi.dot(Ea),m=Yi.dot(Ea);if(m>=0&&f<=m)return e.copy(s);const v=f*c-l*m;if(v<=0&&c>=0&&m<=0)return o=c/(c-m),e.copy(n).addScaledVector(Yi,o);const g=h*m-f*u;if(g<=0&&u-h>=0&&f-m>=0)return lc.subVectors(s,i),o=(u-h)/(u-h+(f-m)),e.copy(i).addScaledVector(lc,o);const p=1/(g+v+d);return a=v*p,o=d*p,e.copy(n).addScaledVector(qi,a).addScaledVector(Yi,o)}equals(t){return t.a.equals(this.a)&&t.b.equals(this.b)&&t.c.equals(this.c)}}const eu={aliceblue:15792383,antiquewhite:16444375,aqua:65535,aquamarine:8388564,azure:15794175,beige:16119260,bisque:16770244,black:0,blanchedalmond:16772045,blue:255,blueviolet:9055202,brown:10824234,burlywood:14596231,cadetblue:6266528,chartreuse:8388352,chocolate:13789470,coral:16744272,cornflowerblue:6591981,cornsilk:16775388,crimson:14423100,cyan:65535,darkblue:139,darkcyan:35723,darkgoldenrod:12092939,darkgray:11119017,darkgreen:25600,darkgrey:11119017,darkkhaki:12433259,darkmagenta:9109643,darkolivegreen:5597999,darkorange:16747520,darkorchid:10040012,darkred:9109504,darksalmon:15308410,darkseagreen:9419919,darkslateblue:4734347,darkslategray:3100495,darkslategrey:3100495,darkturquoise:52945,darkviolet:9699539,deeppink:16716947,deepskyblue:49151,dimgray:6908265,dimgrey:6908265,dodgerblue:2003199,firebrick:11674146,floralwhite:16775920,forestgreen:2263842,fuchsia:16711935,gainsboro:14474460,ghostwhite:16316671,gold:16766720,goldenrod:14329120,gray:8421504,green:32768,greenyellow:11403055,grey:8421504,honeydew:15794160,hotpink:16738740,indianred:13458524,indigo:4915330,ivory:16777200,khaki:15787660,lavender:15132410,lavenderblush:16773365,lawngreen:8190976,lemonchiffon:16775885,lightblue:11393254,lightcoral:15761536,lightcyan:14745599,lightgoldenrodyellow:16448210,lightgray:13882323,lightgreen:9498256,lightgrey:13882323,lightpink:16758465,lightsalmon:16752762,lightseagreen:2142890,lightskyblue:8900346,lightslategray:7833753,lightslategrey:7833753,lightsteelblue:11584734,lightyellow:16777184,lime:65280,limegreen:3329330,linen:16445670,magenta:16711935,maroon:8388608,mediumaquamarine:6737322,mediumblue:205,mediumorchid:12211667,mediumpurple:9662683,mediumseagreen:3978097,mediumslateblue:8087790,mediumspringgreen:64154,mediumturquoise:4772300,mediumvioletred:13047173,midnightblue:1644912,mintcream:16121850,mistyrose:16770273,moccasin:16770229,navajowhite:16768685,navy:128,oldlace:16643558,olive:8421376,olivedrab:7048739,orange:16753920,orangered:16729344,orchid:14315734,palegoldenrod:15657130,palegreen:10025880,paleturquoise:11529966,palevioletred:14381203,papayawhip:16773077,peachpuff:16767673,peru:13468991,pink:16761035,plum:14524637,powderblue:11591910,purple:8388736,rebeccapurple:6697881,red:16711680,rosybrown:12357519,royalblue:4286945,saddlebrown:9127187,salmon:16416882,sandybrown:16032864,seagreen:3050327,seashell:16774638,sienna:10506797,silver:12632256,skyblue:8900331,slateblue:6970061,slategray:7372944,slategrey:7372944,snow:16775930,springgreen:65407,steelblue:4620980,tan:13808780,teal:32896,thistle:14204888,tomato:16737095,turquoise:4251856,violet:15631086,wheat:16113331,white:16777215,whitesmoke:16119285,yellow:16776960,yellowgreen:10145074},ai={h:0,s:0,l:0},gr={h:0,s:0,l:0};function Pa(r,t,e){return e<0&&(e+=1),e>1&&(e-=1),e<1/6?r+(t-r)*6*e:e<1/2?t:e<2/3?r+(t-r)*6*(2/3-e):r}class dt{constructor(t,e,n){return this.isColor=!0,this.r=1,this.g=1,this.b=1,this.set(t,e,n)}set(t,e,n){if(e===void 0&&n===void 0){const i=t;i&&i.isColor?this.copy(i):typeof i=="number"?this.setHex(i):typeof i=="string"&&this.setStyle(i)}else this.setRGB(t,e,n);return this}setScalar(t){return this.r=t,this.g=t,this.b=t,this}setHex(t,e=be){return t=Math.floor(t),this.r=(t>>16&255)/255,this.g=(t>>8&255)/255,this.b=(t&255)/255,Ht.toWorkingColorSpace(this,e),this}setRGB(t,e,n,i=Ht.workingColorSpace){return this.r=t,this.g=e,this.b=n,Ht.toWorkingColorSpace(this,i),this}setHSL(t,e,n,i=Ht.workingColorSpace){if(t=ul(t,1),e=Ae(e,0,1),n=Ae(n,0,1),e===0)this.r=this.g=this.b=n;else{const s=n<=.5?n*(1+e):n+e-n*e,a=2*n-s;this.r=Pa(a,s,t+1/3),this.g=Pa(a,s,t),this.b=Pa(a,s,t-1/3)}return Ht.toWorkingColorSpace(this,i),this}setStyle(t,e=be){function n(s){s!==void 0&&parseFloat(s)<1&&console.warn("THREE.Color: Alpha component of "+t+" will be ignored.")}let i;if(i=/^(\w+)\(([^\)]*)\)/.exec(t)){let s;const a=i[1],o=i[2];switch(a){case"rgb":case"rgba":if(s=/^\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o))return n(s[4]),this.setRGB(Math.min(255,parseInt(s[1],10))/255,Math.min(255,parseInt(s[2],10))/255,Math.min(255,parseInt(s[3],10))/255,e);if(s=/^\s*(\d+)\%\s*,\s*(\d+)\%\s*,\s*(\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o))return n(s[4]),this.setRGB(Math.min(100,parseInt(s[1],10))/100,Math.min(100,parseInt(s[2],10))/100,Math.min(100,parseInt(s[3],10))/100,e);break;case"hsl":case"hsla":if(s=/^\s*(\d*\.?\d+)\s*,\s*(\d*\.?\d+)\%\s*,\s*(\d*\.?\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(o))return n(s[4]),this.setHSL(parseFloat(s[1])/360,parseFloat(s[2])/100,parseFloat(s[3])/100,e);break;default:console.warn("THREE.Color: Unknown color model "+t)}}else if(i=/^\#([A-Fa-f\d]+)$/.exec(t)){const s=i[1],a=s.length;if(a===3)return this.setRGB(parseInt(s.charAt(0),16)/15,parseInt(s.charAt(1),16)/15,parseInt(s.charAt(2),16)/15,e);if(a===6)return this.setHex(parseInt(s,16),e);console.warn("THREE.Color: Invalid hex color "+t)}else if(t&&t.length>0)return this.setColorName(t,e);return this}setColorName(t,e=be){const n=eu[t.toLowerCase()];return n!==void 0?this.setHex(n,e):console.warn("THREE.Color: Unknown color "+t),this}clone(){return new this.constructor(this.r,this.g,this.b)}copy(t){return this.r=t.r,this.g=t.g,this.b=t.b,this}copySRGBToLinear(t){return this.r=jn(t.r),this.g=jn(t.g),this.b=jn(t.b),this}copyLinearToSRGB(t){return this.r=ss(t.r),this.g=ss(t.g),this.b=ss(t.b),this}convertSRGBToLinear(){return this.copySRGBToLinear(this),this}convertLinearToSRGB(){return this.copyLinearToSRGB(this),this}getHex(t=be){return Ht.fromWorkingColorSpace(ke.copy(this),t),Math.round(Ae(ke.r*255,0,255))*65536+Math.round(Ae(ke.g*255,0,255))*256+Math.round(Ae(ke.b*255,0,255))}getHexString(t=be){return("000000"+this.getHex(t).toString(16)).slice(-6)}getHSL(t,e=Ht.workingColorSpace){Ht.fromWorkingColorSpace(ke.copy(this),e);const n=ke.r,i=ke.g,s=ke.b,a=Math.max(n,i,s),o=Math.min(n,i,s);let l,c;const h=(o+a)/2;if(o===a)l=0,c=0;else{const u=a-o;switch(c=h<=.5?u/(a+o):u/(2-a-o),a){case n:l=(i-s)/u+(i<s?6:0);break;case i:l=(s-n)/u+2;break;case s:l=(n-i)/u+4;break}l/=6}return t.h=l,t.s=c,t.l=h,t}getRGB(t,e=Ht.workingColorSpace){return Ht.fromWorkingColorSpace(ke.copy(this),e),t.r=ke.r,t.g=ke.g,t.b=ke.b,t}getStyle(t=be){Ht.fromWorkingColorSpace(ke.copy(this),t);const e=ke.r,n=ke.g,i=ke.b;return t!==be?`color(${t} ${e.toFixed(3)} ${n.toFixed(3)} ${i.toFixed(3)})`:`rgb(${Math.round(e*255)},${Math.round(n*255)},${Math.round(i*255)})`}offsetHSL(t,e,n){return this.getHSL(ai),this.setHSL(ai.h+t,ai.s+e,ai.l+n)}add(t){return this.r+=t.r,this.g+=t.g,this.b+=t.b,this}addColors(t,e){return this.r=t.r+e.r,this.g=t.g+e.g,this.b=t.b+e.b,this}addScalar(t){return this.r+=t,this.g+=t,this.b+=t,this}sub(t){return this.r=Math.max(0,this.r-t.r),this.g=Math.max(0,this.g-t.g),this.b=Math.max(0,this.b-t.b),this}multiply(t){return this.r*=t.r,this.g*=t.g,this.b*=t.b,this}multiplyScalar(t){return this.r*=t,this.g*=t,this.b*=t,this}lerp(t,e){return this.r+=(t.r-this.r)*e,this.g+=(t.g-this.g)*e,this.b+=(t.b-this.b)*e,this}lerpColors(t,e,n){return this.r=t.r+(e.r-t.r)*n,this.g=t.g+(e.g-t.g)*n,this.b=t.b+(e.b-t.b)*n,this}lerpHSL(t,e){this.getHSL(ai),t.getHSL(gr);const n=Gs(ai.h,gr.h,e),i=Gs(ai.s,gr.s,e),s=Gs(ai.l,gr.l,e);return this.setHSL(n,i,s),this}setFromVector3(t){return this.r=t.x,this.g=t.y,this.b=t.z,this}applyMatrix3(t){const e=this.r,n=this.g,i=this.b,s=t.elements;return this.r=s[0]*e+s[3]*n+s[6]*i,this.g=s[1]*e+s[4]*n+s[7]*i,this.b=s[2]*e+s[5]*n+s[8]*i,this}equals(t){return t.r===this.r&&t.g===this.g&&t.b===this.b}fromArray(t,e=0){return this.r=t[e],this.g=t[e+1],this.b=t[e+2],this}toArray(t=[],e=0){return t[e]=this.r,t[e+1]=this.g,t[e+2]=this.b,t}fromBufferAttribute(t,e){return this.r=t.getX(e),this.g=t.getY(e),this.b=t.getZ(e),this}toJSON(){return this.getHex()}*[Symbol.iterator](){yield this.r,yield this.g,yield this.b}}const ke=new dt;dt.NAMES=eu;let ff=0;class Tn extends _s{static get type(){return"Material"}get type(){return this.constructor.type}set type(t){}constructor(){super(),this.isMaterial=!0,Object.defineProperty(this,"id",{value:ff++}),this.uuid=wn(),this.name="",this.blending=mi,this.side=Zn,this.vertexColors=!1,this.opacity=1,this.transparent=!1,this.alphaHash=!1,this.blendSrc=no,this.blendDst=io,this.blendEquation=Li,this.blendSrcAlpha=null,this.blendDstAlpha=null,this.blendEquationAlpha=null,this.blendColor=new dt(0,0,0),this.blendAlpha=0,this.depthFunc=as,this.depthTest=!0,this.depthWrite=!0,this.stencilWriteMask=255,this.stencilFunc=Xl,this.stencilRef=0,this.stencilFuncMask=255,this.stencilFail=ki,this.stencilZFail=ki,this.stencilZPass=ki,this.stencilWrite=!1,this.clippingPlanes=null,this.clipIntersection=!1,this.clipShadows=!1,this.shadowSide=null,this.colorWrite=!0,this.precision=null,this.polygonOffset=!1,this.polygonOffsetFactor=0,this.polygonOffsetUnits=0,this.dithering=!1,this.alphaToCoverage=!1,this.premultipliedAlpha=!1,this.forceSinglePass=!1,this.visible=!0,this.toneMapped=!0,this.userData={},this.version=0,this._alphaTest=0}get alphaTest(){return this._alphaTest}set alphaTest(t){this._alphaTest>0!=t>0&&this.version++,this._alphaTest=t}onBeforeRender(){}onBeforeCompile(){}customProgramCacheKey(){return this.onBeforeCompile.toString()}setValues(t){if(t!==void 0)for(const e in t){const n=t[e];if(n===void 0){console.warn(`THREE.Material: parameter '${e}' has value of undefined.`);continue}const i=this[e];if(i===void 0){console.warn(`THREE.Material: '${e}' is not a property of THREE.${this.type}.`);continue}i&&i.isColor?i.set(n):i&&i.isVector3&&n&&n.isVector3?i.copy(n):this[e]=n}}toJSON(t){const e=t===void 0||typeof t=="string";e&&(t={textures:{},images:{}});const n={metadata:{version:4.6,type:"Material",generator:"Material.toJSON"}};n.uuid=this.uuid,n.type=this.type,this.name!==""&&(n.name=this.name),this.color&&this.color.isColor&&(n.color=this.color.getHex()),this.roughness!==void 0&&(n.roughness=this.roughness),this.metalness!==void 0&&(n.metalness=this.metalness),this.sheen!==void 0&&(n.sheen=this.sheen),this.sheenColor&&this.sheenColor.isColor&&(n.sheenColor=this.sheenColor.getHex()),this.sheenRoughness!==void 0&&(n.sheenRoughness=this.sheenRoughness),this.emissive&&this.emissive.isColor&&(n.emissive=this.emissive.getHex()),this.emissiveIntensity!==void 0&&this.emissiveIntensity!==1&&(n.emissiveIntensity=this.emissiveIntensity),this.specular&&this.specular.isColor&&(n.specular=this.specular.getHex()),this.specularIntensity!==void 0&&(n.specularIntensity=this.specularIntensity),this.specularColor&&this.specularColor.isColor&&(n.specularColor=this.specularColor.getHex()),this.shininess!==void 0&&(n.shininess=this.shininess),this.clearcoat!==void 0&&(n.clearcoat=this.clearcoat),this.clearcoatRoughness!==void 0&&(n.clearcoatRoughness=this.clearcoatRoughness),this.clearcoatMap&&this.clearcoatMap.isTexture&&(n.clearcoatMap=this.clearcoatMap.toJSON(t).uuid),this.clearcoatRoughnessMap&&this.clearcoatRoughnessMap.isTexture&&(n.clearcoatRoughnessMap=this.clearcoatRoughnessMap.toJSON(t).uuid),this.clearcoatNormalMap&&this.clearcoatNormalMap.isTexture&&(n.clearcoatNormalMap=this.clearcoatNormalMap.toJSON(t).uuid,n.clearcoatNormalScale=this.clearcoatNormalScale.toArray()),this.dispersion!==void 0&&(n.dispersion=this.dispersion),this.iridescence!==void 0&&(n.iridescence=this.iridescence),this.iridescenceIOR!==void 0&&(n.iridescenceIOR=this.iridescenceIOR),this.iridescenceThicknessRange!==void 0&&(n.iridescenceThicknessRange=this.iridescenceThicknessRange),this.iridescenceMap&&this.iridescenceMap.isTexture&&(n.iridescenceMap=this.iridescenceMap.toJSON(t).uuid),this.iridescenceThicknessMap&&this.iridescenceThicknessMap.isTexture&&(n.iridescenceThicknessMap=this.iridescenceThicknessMap.toJSON(t).uuid),this.anisotropy!==void 0&&(n.anisotropy=this.anisotropy),this.anisotropyRotation!==void 0&&(n.anisotropyRotation=this.anisotropyRotation),this.anisotropyMap&&this.anisotropyMap.isTexture&&(n.anisotropyMap=this.anisotropyMap.toJSON(t).uuid),this.map&&this.map.isTexture&&(n.map=this.map.toJSON(t).uuid),this.matcap&&this.matcap.isTexture&&(n.matcap=this.matcap.toJSON(t).uuid),this.alphaMap&&this.alphaMap.isTexture&&(n.alphaMap=this.alphaMap.toJSON(t).uuid),this.lightMap&&this.lightMap.isTexture&&(n.lightMap=this.lightMap.toJSON(t).uuid,n.lightMapIntensity=this.lightMapIntensity),this.aoMap&&this.aoMap.isTexture&&(n.aoMap=this.aoMap.toJSON(t).uuid,n.aoMapIntensity=this.aoMapIntensity),this.bumpMap&&this.bumpMap.isTexture&&(n.bumpMap=this.bumpMap.toJSON(t).uuid,n.bumpScale=this.bumpScale),this.normalMap&&this.normalMap.isTexture&&(n.normalMap=this.normalMap.toJSON(t).uuid,n.normalMapType=this.normalMapType,n.normalScale=this.normalScale.toArray()),this.displacementMap&&this.displacementMap.isTexture&&(n.displacementMap=this.displacementMap.toJSON(t).uuid,n.displacementScale=this.displacementScale,n.displacementBias=this.displacementBias),this.roughnessMap&&this.roughnessMap.isTexture&&(n.roughnessMap=this.roughnessMap.toJSON(t).uuid),this.metalnessMap&&this.metalnessMap.isTexture&&(n.metalnessMap=this.metalnessMap.toJSON(t).uuid),this.emissiveMap&&this.emissiveMap.isTexture&&(n.emissiveMap=this.emissiveMap.toJSON(t).uuid),this.specularMap&&this.specularMap.isTexture&&(n.specularMap=this.specularMap.toJSON(t).uuid),this.specularIntensityMap&&this.specularIntensityMap.isTexture&&(n.specularIntensityMap=this.specularIntensityMap.toJSON(t).uuid),this.specularColorMap&&this.specularColorMap.isTexture&&(n.specularColorMap=this.specularColorMap.toJSON(t).uuid),this.envMap&&this.envMap.isTexture&&(n.envMap=this.envMap.toJSON(t).uuid,this.combine!==void 0&&(n.combine=this.combine)),this.envMapRotation!==void 0&&(n.envMapRotation=this.envMapRotation.toArray()),this.envMapIntensity!==void 0&&(n.envMapIntensity=this.envMapIntensity),this.reflectivity!==void 0&&(n.reflectivity=this.reflectivity),this.refractionRatio!==void 0&&(n.refractionRatio=this.refractionRatio),this.gradientMap&&this.gradientMap.isTexture&&(n.gradientMap=this.gradientMap.toJSON(t).uuid),this.transmission!==void 0&&(n.transmission=this.transmission),this.transmissionMap&&this.transmissionMap.isTexture&&(n.transmissionMap=this.transmissionMap.toJSON(t).uuid),this.thickness!==void 0&&(n.thickness=this.thickness),this.thicknessMap&&this.thicknessMap.isTexture&&(n.thicknessMap=this.thicknessMap.toJSON(t).uuid),this.attenuationDistance!==void 0&&this.attenuationDistance!==1/0&&(n.attenuationDistance=this.attenuationDistance),this.attenuationColor!==void 0&&(n.attenuationColor=this.attenuationColor.getHex()),this.size!==void 0&&(n.size=this.size),this.shadowSide!==null&&(n.shadowSide=this.shadowSide),this.sizeAttenuation!==void 0&&(n.sizeAttenuation=this.sizeAttenuation),this.blending!==mi&&(n.blending=this.blending),this.side!==Zn&&(n.side=this.side),this.vertexColors===!0&&(n.vertexColors=!0),this.opacity<1&&(n.opacity=this.opacity),this.transparent===!0&&(n.transparent=!0),this.blendSrc!==no&&(n.blendSrc=this.blendSrc),this.blendDst!==io&&(n.blendDst=this.blendDst),this.blendEquation!==Li&&(n.blendEquation=this.blendEquation),this.blendSrcAlpha!==null&&(n.blendSrcAlpha=this.blendSrcAlpha),this.blendDstAlpha!==null&&(n.blendDstAlpha=this.blendDstAlpha),this.blendEquationAlpha!==null&&(n.blendEquationAlpha=this.blendEquationAlpha),this.blendColor&&this.blendColor.isColor&&(n.blendColor=this.blendColor.getHex()),this.blendAlpha!==0&&(n.blendAlpha=this.blendAlpha),this.depthFunc!==as&&(n.depthFunc=this.depthFunc),this.depthTest===!1&&(n.depthTest=this.depthTest),this.depthWrite===!1&&(n.depthWrite=this.depthWrite),this.colorWrite===!1&&(n.colorWrite=this.colorWrite),this.stencilWriteMask!==255&&(n.stencilWriteMask=this.stencilWriteMask),this.stencilFunc!==Xl&&(n.stencilFunc=this.stencilFunc),this.stencilRef!==0&&(n.stencilRef=this.stencilRef),this.stencilFuncMask!==255&&(n.stencilFuncMask=this.stencilFuncMask),this.stencilFail!==ki&&(n.stencilFail=this.stencilFail),this.stencilZFail!==ki&&(n.stencilZFail=this.stencilZFail),this.stencilZPass!==ki&&(n.stencilZPass=this.stencilZPass),this.stencilWrite===!0&&(n.stencilWrite=this.stencilWrite),this.rotation!==void 0&&this.rotation!==0&&(n.rotation=this.rotation),this.polygonOffset===!0&&(n.polygonOffset=!0),this.polygonOffsetFactor!==0&&(n.polygonOffsetFactor=this.polygonOffsetFactor),this.polygonOffsetUnits!==0&&(n.polygonOffsetUnits=this.polygonOffsetUnits),this.linewidth!==void 0&&this.linewidth!==1&&(n.linewidth=this.linewidth),this.dashSize!==void 0&&(n.dashSize=this.dashSize),this.gapSize!==void 0&&(n.gapSize=this.gapSize),this.scale!==void 0&&(n.scale=this.scale),this.dithering===!0&&(n.dithering=!0),this.alphaTest>0&&(n.alphaTest=this.alphaTest),this.alphaHash===!0&&(n.alphaHash=!0),this.alphaToCoverage===!0&&(n.alphaToCoverage=!0),this.premultipliedAlpha===!0&&(n.premultipliedAlpha=!0),this.forceSinglePass===!0&&(n.forceSinglePass=!0),this.wireframe===!0&&(n.wireframe=!0),this.wireframeLinewidth>1&&(n.wireframeLinewidth=this.wireframeLinewidth),this.wireframeLinecap!=="round"&&(n.wireframeLinecap=this.wireframeLinecap),this.wireframeLinejoin!=="round"&&(n.wireframeLinejoin=this.wireframeLinejoin),this.flatShading===!0&&(n.flatShading=!0),this.visible===!1&&(n.visible=!1),this.toneMapped===!1&&(n.toneMapped=!1),this.fog===!1&&(n.fog=!1),Object.keys(this.userData).length>0&&(n.userData=this.userData);function i(s){const a=[];for(const o in s){const l=s[o];delete l.metadata,a.push(l)}return a}if(e){const s=i(t.textures),a=i(t.images);s.length>0&&(n.textures=s),a.length>0&&(n.images=a)}return n}clone(){return new this.constructor().copy(this)}copy(t){this.name=t.name,this.blending=t.blending,this.side=t.side,this.vertexColors=t.vertexColors,this.opacity=t.opacity,this.transparent=t.transparent,this.blendSrc=t.blendSrc,this.blendDst=t.blendDst,this.blendEquation=t.blendEquation,this.blendSrcAlpha=t.blendSrcAlpha,this.blendDstAlpha=t.blendDstAlpha,this.blendEquationAlpha=t.blendEquationAlpha,this.blendColor.copy(t.blendColor),this.blendAlpha=t.blendAlpha,this.depthFunc=t.depthFunc,this.depthTest=t.depthTest,this.depthWrite=t.depthWrite,this.stencilWriteMask=t.stencilWriteMask,this.stencilFunc=t.stencilFunc,this.stencilRef=t.stencilRef,this.stencilFuncMask=t.stencilFuncMask,this.stencilFail=t.stencilFail,this.stencilZFail=t.stencilZFail,this.stencilZPass=t.stencilZPass,this.stencilWrite=t.stencilWrite;const e=t.clippingPlanes;let n=null;if(e!==null){const i=e.length;n=new Array(i);for(let s=0;s!==i;++s)n[s]=e[s].clone()}return this.clippingPlanes=n,this.clipIntersection=t.clipIntersection,this.clipShadows=t.clipShadows,this.shadowSide=t.shadowSide,this.colorWrite=t.colorWrite,this.precision=t.precision,this.polygonOffset=t.polygonOffset,this.polygonOffsetFactor=t.polygonOffsetFactor,this.polygonOffsetUnits=t.polygonOffsetUnits,this.dithering=t.dithering,this.alphaTest=t.alphaTest,this.alphaHash=t.alphaHash,this.alphaToCoverage=t.alphaToCoverage,this.premultipliedAlpha=t.premultipliedAlpha,this.forceSinglePass=t.forceSinglePass,this.visible=t.visible,this.toneMapped=t.toneMapped,this.userData=JSON.parse(JSON.stringify(t.userData)),this}dispose(){this.dispatchEvent({type:"dispose"})}set needsUpdate(t){t===!0&&this.version++}onBuild(){console.warn("Material: onBuild() has been removed.")}}class ne extends Tn{static get type(){return"MeshBasicMaterial"}constructor(t){super(),this.isMeshBasicMaterial=!0,this.color=new dt(16777215),this.map=null,this.lightMap=null,this.lightMapIntensity=1,this.aoMap=null,this.aoMapIntensity=1,this.specularMap=null,this.alphaMap=null,this.envMap=null,this.envMapRotation=new En,this.combine=el,this.reflectivity=1,this.refractionRatio=.98,this.wireframe=!1,this.wireframeLinewidth=1,this.wireframeLinecap="round",this.wireframeLinejoin="round",this.fog=!0,this.setValues(t)}copy(t){return super.copy(t),this.color.copy(t.color),this.map=t.map,this.lightMap=t.lightMap,this.lightMapIntensity=t.lightMapIntensity,this.aoMap=t.aoMap,this.aoMapIntensity=t.aoMapIntensity,this.specularMap=t.specularMap,this.alphaMap=t.alphaMap,this.envMap=t.envMap,this.envMapRotation.copy(t.envMapRotation),this.combine=t.combine,this.reflectivity=t.reflectivity,this.refractionRatio=t.refractionRatio,this.wireframe=t.wireframe,this.wireframeLinewidth=t.wireframeLinewidth,this.wireframeLinecap=t.wireframeLinecap,this.wireframeLinejoin=t.wireframeLinejoin,this.fog=t.fog,this}}const we=new P,vr=new nt;class ge{constructor(t,e,n=!1){if(Array.isArray(t))throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");this.isBufferAttribute=!0,this.name="",this.array=t,this.itemSize=e,this.count=t!==void 0?t.length/e:0,this.normalized=n,this.usage=Ho,this.updateRanges=[],this.gpuType=Sn,this.version=0}onUploadCallback(){}set needsUpdate(t){t===!0&&this.version++}setUsage(t){return this.usage=t,this}addUpdateRange(t,e){this.updateRanges.push({start:t,count:e})}clearUpdateRanges(){this.updateRanges.length=0}copy(t){return this.name=t.name,this.array=new t.array.constructor(t.array),this.itemSize=t.itemSize,this.count=t.count,this.normalized=t.normalized,this.usage=t.usage,this.gpuType=t.gpuType,this}copyAt(t,e,n){t*=this.itemSize,n*=e.itemSize;for(let i=0,s=this.itemSize;i<s;i++)this.array[t+i]=e.array[n+i];return this}copyArray(t){return this.array.set(t),this}applyMatrix3(t){if(this.itemSize===2)for(let e=0,n=this.count;e<n;e++)vr.fromBufferAttribute(this,e),vr.applyMatrix3(t),this.setXY(e,vr.x,vr.y);else if(this.itemSize===3)for(let e=0,n=this.count;e<n;e++)we.fromBufferAttribute(this,e),we.applyMatrix3(t),this.setXYZ(e,we.x,we.y,we.z);return this}applyMatrix4(t){for(let e=0,n=this.count;e<n;e++)we.fromBufferAttribute(this,e),we.applyMatrix4(t),this.setXYZ(e,we.x,we.y,we.z);return this}applyNormalMatrix(t){for(let e=0,n=this.count;e<n;e++)we.fromBufferAttribute(this,e),we.applyNormalMatrix(t),this.setXYZ(e,we.x,we.y,we.z);return this}transformDirection(t){for(let e=0,n=this.count;e<n;e++)we.fromBufferAttribute(this,e),we.transformDirection(t),this.setXYZ(e,we.x,we.y,we.z);return this}set(t,e=0){return this.array.set(t,e),this}getComponent(t,e){let n=this.array[t*this.itemSize+e];return this.normalized&&(n=Mn(n,this.array)),n}setComponent(t,e,n){return this.normalized&&(n=ae(n,this.array)),this.array[t*this.itemSize+e]=n,this}getX(t){let e=this.array[t*this.itemSize];return this.normalized&&(e=Mn(e,this.array)),e}setX(t,e){return this.normalized&&(e=ae(e,this.array)),this.array[t*this.itemSize]=e,this}getY(t){let e=this.array[t*this.itemSize+1];return this.normalized&&(e=Mn(e,this.array)),e}setY(t,e){return this.normalized&&(e=ae(e,this.array)),this.array[t*this.itemSize+1]=e,this}getZ(t){let e=this.array[t*this.itemSize+2];return this.normalized&&(e=Mn(e,this.array)),e}setZ(t,e){return this.normalized&&(e=ae(e,this.array)),this.array[t*this.itemSize+2]=e,this}getW(t){let e=this.array[t*this.itemSize+3];return this.normalized&&(e=Mn(e,this.array)),e}setW(t,e){return this.normalized&&(e=ae(e,this.array)),this.array[t*this.itemSize+3]=e,this}setXY(t,e,n){return t*=this.itemSize,this.normalized&&(e=ae(e,this.array),n=ae(n,this.array)),this.array[t+0]=e,this.array[t+1]=n,this}setXYZ(t,e,n,i){return t*=this.itemSize,this.normalized&&(e=ae(e,this.array),n=ae(n,this.array),i=ae(i,this.array)),this.array[t+0]=e,this.array[t+1]=n,this.array[t+2]=i,this}setXYZW(t,e,n,i,s){return t*=this.itemSize,this.normalized&&(e=ae(e,this.array),n=ae(n,this.array),i=ae(i,this.array),s=ae(s,this.array)),this.array[t+0]=e,this.array[t+1]=n,this.array[t+2]=i,this.array[t+3]=s,this}onUpload(t){return this.onUploadCallback=t,this}clone(){return new this.constructor(this.array,this.itemSize).copy(this)}toJSON(){const t={itemSize:this.itemSize,type:this.array.constructor.name,array:Array.from(this.array),normalized:this.normalized};return this.name!==""&&(t.name=this.name),this.usage!==Ho&&(t.usage=this.usage),t}}class nu extends ge{constructor(t,e,n){super(new Uint16Array(t),e,n)}}class iu extends ge{constructor(t,e,n){super(new Uint32Array(t),e,n)}}class Vt extends ge{constructor(t,e,n){super(new Float32Array(t),e,n)}}let pf=0;const rn=new It,La=new he,Ki=new P,Je=new Qn,Ps=new Qn,Ie=new P;class ye extends _s{constructor(){super(),this.isBufferGeometry=!0,Object.defineProperty(this,"id",{value:pf++}),this.uuid=wn(),this.name="",this.type="BufferGeometry",this.index=null,this.indirect=null,this.attributes={},this.morphAttributes={},this.morphTargetsRelative=!1,this.groups=[],this.boundingBox=null,this.boundingSphere=null,this.drawRange={start:0,count:1/0},this.userData={}}getIndex(){return this.index}setIndex(t){return Array.isArray(t)?this.index=new(Zh(t)?iu:nu)(t,1):this.index=t,this}setIndirect(t){return this.indirect=t,this}getIndirect(){return this.indirect}getAttribute(t){return this.attributes[t]}setAttribute(t,e){return this.attributes[t]=e,this}deleteAttribute(t){return delete this.attributes[t],this}hasAttribute(t){return this.attributes[t]!==void 0}addGroup(t,e,n=0){this.groups.push({start:t,count:e,materialIndex:n})}clearGroups(){this.groups=[]}setDrawRange(t,e){this.drawRange.start=t,this.drawRange.count=e}applyMatrix4(t){const e=this.attributes.position;e!==void 0&&(e.applyMatrix4(t),e.needsUpdate=!0);const n=this.attributes.normal;if(n!==void 0){const s=new Ut().getNormalMatrix(t);n.applyNormalMatrix(s),n.needsUpdate=!0}const i=this.attributes.tangent;return i!==void 0&&(i.transformDirection(t),i.needsUpdate=!0),this.boundingBox!==null&&this.computeBoundingBox(),this.boundingSphere!==null&&this.computeBoundingSphere(),this}applyQuaternion(t){return rn.makeRotationFromQuaternion(t),this.applyMatrix4(rn),this}rotateX(t){return rn.makeRotationX(t),this.applyMatrix4(rn),this}rotateY(t){return rn.makeRotationY(t),this.applyMatrix4(rn),this}rotateZ(t){return rn.makeRotationZ(t),this.applyMatrix4(rn),this}translate(t,e,n){return rn.makeTranslation(t,e,n),this.applyMatrix4(rn),this}scale(t,e,n){return rn.makeScale(t,e,n),this.applyMatrix4(rn),this}lookAt(t){return La.lookAt(t),La.updateMatrix(),this.applyMatrix4(La.matrix),this}center(){return this.computeBoundingBox(),this.boundingBox.getCenter(Ki).negate(),this.translate(Ki.x,Ki.y,Ki.z),this}setFromPoints(t){const e=this.getAttribute("position");if(e===void 0){const n=[];for(let i=0,s=t.length;i<s;i++){const a=t[i];n.push(a.x,a.y,a.z||0)}this.setAttribute("position",new Vt(n,3))}else{for(let n=0,i=e.count;n<i;n++){const s=t[n];e.setXYZ(n,s.x,s.y,s.z||0)}t.length>e.count&&console.warn("THREE.BufferGeometry: Buffer size too small for points data. Use .dispose() and create a new geometry."),e.needsUpdate=!0}return this}computeBoundingBox(){this.boundingBox===null&&(this.boundingBox=new Qn);const t=this.attributes.position,e=this.morphAttributes.position;if(t&&t.isGLBufferAttribute){console.error("THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.",this),this.boundingBox.set(new P(-1/0,-1/0,-1/0),new P(1/0,1/0,1/0));return}if(t!==void 0){if(this.boundingBox.setFromBufferAttribute(t),e)for(let n=0,i=e.length;n<i;n++){const s=e[n];Je.setFromBufferAttribute(s),this.morphTargetsRelative?(Ie.addVectors(this.boundingBox.min,Je.min),this.boundingBox.expandByPoint(Ie),Ie.addVectors(this.boundingBox.max,Je.max),this.boundingBox.expandByPoint(Ie)):(this.boundingBox.expandByPoint(Je.min),this.boundingBox.expandByPoint(Je.max))}}else this.boundingBox.makeEmpty();(isNaN(this.boundingBox.min.x)||isNaN(this.boundingBox.min.y)||isNaN(this.boundingBox.min.z))&&console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.',this)}computeBoundingSphere(){this.boundingSphere===null&&(this.boundingSphere=new Ln);const t=this.attributes.position,e=this.morphAttributes.position;if(t&&t.isGLBufferAttribute){console.error("THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.",this),this.boundingSphere.set(new P,1/0);return}if(t){const n=this.boundingSphere.center;if(Je.setFromBufferAttribute(t),e)for(let s=0,a=e.length;s<a;s++){const o=e[s];Ps.setFromBufferAttribute(o),this.morphTargetsRelative?(Ie.addVectors(Je.min,Ps.min),Je.expandByPoint(Ie),Ie.addVectors(Je.max,Ps.max),Je.expandByPoint(Ie)):(Je.expandByPoint(Ps.min),Je.expandByPoint(Ps.max))}Je.getCenter(n);let i=0;for(let s=0,a=t.count;s<a;s++)Ie.fromBufferAttribute(t,s),i=Math.max(i,n.distanceToSquared(Ie));if(e)for(let s=0,a=e.length;s<a;s++){const o=e[s],l=this.morphTargetsRelative;for(let c=0,h=o.count;c<h;c++)Ie.fromBufferAttribute(o,c),l&&(Ki.fromBufferAttribute(t,c),Ie.add(Ki)),i=Math.max(i,n.distanceToSquared(Ie))}this.boundingSphere.radius=Math.sqrt(i),isNaN(this.boundingSphere.radius)&&console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.',this)}}computeTangents(){const t=this.index,e=this.attributes;if(t===null||e.position===void 0||e.normal===void 0||e.uv===void 0){console.error("THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)");return}const n=e.position,i=e.normal,s=e.uv;this.hasAttribute("tangent")===!1&&this.setAttribute("tangent",new ge(new Float32Array(4*n.count),4));const a=this.getAttribute("tangent"),o=[],l=[];for(let C=0;C<n.count;C++)o[C]=new P,l[C]=new P;const c=new P,h=new P,u=new P,d=new nt,f=new nt,m=new nt,v=new P,g=new P;function p(C,b,M){c.fromBufferAttribute(n,C),h.fromBufferAttribute(n,b),u.fromBufferAttribute(n,M),d.fromBufferAttribute(s,C),f.fromBufferAttribute(s,b),m.fromBufferAttribute(s,M),h.sub(c),u.sub(c),f.sub(d),m.sub(d);const L=1/(f.x*m.y-m.x*f.y);isFinite(L)&&(v.copy(h).multiplyScalar(m.y).addScaledVector(u,-f.y).multiplyScalar(L),g.copy(u).multiplyScalar(f.x).addScaledVector(h,-m.x).multiplyScalar(L),o[C].add(v),o[b].add(v),o[M].add(v),l[C].add(g),l[b].add(g),l[M].add(g))}let x=this.groups;x.length===0&&(x=[{start:0,count:t.count}]);for(let C=0,b=x.length;C<b;++C){const M=x[C],L=M.start,z=M.count;for(let R=L,B=L+z;R<B;R+=3)p(t.getX(R+0),t.getX(R+1),t.getX(R+2))}const y=new P,_=new P,I=new P,E=new P;function A(C){I.fromBufferAttribute(i,C),E.copy(I);const b=o[C];y.copy(b),y.sub(I.multiplyScalar(I.dot(b))).normalize(),_.crossVectors(E,b);const L=_.dot(l[C])<0?-1:1;a.setXYZW(C,y.x,y.y,y.z,L)}for(let C=0,b=x.length;C<b;++C){const M=x[C],L=M.start,z=M.count;for(let R=L,B=L+z;R<B;R+=3)A(t.getX(R+0)),A(t.getX(R+1)),A(t.getX(R+2))}}computeVertexNormals(){const t=this.index,e=this.getAttribute("position");if(e!==void 0){let n=this.getAttribute("normal");if(n===void 0)n=new ge(new Float32Array(e.count*3),3),this.setAttribute("normal",n);else for(let d=0,f=n.count;d<f;d++)n.setXYZ(d,0,0,0);const i=new P,s=new P,a=new P,o=new P,l=new P,c=new P,h=new P,u=new P;if(t)for(let d=0,f=t.count;d<f;d+=3){const m=t.getX(d+0),v=t.getX(d+1),g=t.getX(d+2);i.fromBufferAttribute(e,m),s.fromBufferAttribute(e,v),a.fromBufferAttribute(e,g),h.subVectors(a,s),u.subVectors(i,s),h.cross(u),o.fromBufferAttribute(n,m),l.fromBufferAttribute(n,v),c.fromBufferAttribute(n,g),o.add(h),l.add(h),c.add(h),n.setXYZ(m,o.x,o.y,o.z),n.setXYZ(v,l.x,l.y,l.z),n.setXYZ(g,c.x,c.y,c.z)}else for(let d=0,f=e.count;d<f;d+=3)i.fromBufferAttribute(e,d+0),s.fromBufferAttribute(e,d+1),a.fromBufferAttribute(e,d+2),h.subVectors(a,s),u.subVectors(i,s),h.cross(u),n.setXYZ(d+0,h.x,h.y,h.z),n.setXYZ(d+1,h.x,h.y,h.z),n.setXYZ(d+2,h.x,h.y,h.z);this.normalizeNormals(),n.needsUpdate=!0}}normalizeNormals(){const t=this.attributes.normal;for(let e=0,n=t.count;e<n;e++)Ie.fromBufferAttribute(t,e),Ie.normalize(),t.setXYZ(e,Ie.x,Ie.y,Ie.z)}toNonIndexed(){function t(o,l){const c=o.array,h=o.itemSize,u=o.normalized,d=new c.constructor(l.length*h);let f=0,m=0;for(let v=0,g=l.length;v<g;v++){o.isInterleavedBufferAttribute?f=l[v]*o.data.stride+o.offset:f=l[v]*h;for(let p=0;p<h;p++)d[m++]=c[f++]}return new ge(d,h,u)}if(this.index===null)return console.warn("THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed."),this;const e=new ye,n=this.index.array,i=this.attributes;for(const o in i){const l=i[o],c=t(l,n);e.setAttribute(o,c)}const s=this.morphAttributes;for(const o in s){const l=[],c=s[o];for(let h=0,u=c.length;h<u;h++){const d=c[h],f=t(d,n);l.push(f)}e.morphAttributes[o]=l}e.morphTargetsRelative=this.morphTargetsRelative;const a=this.groups;for(let o=0,l=a.length;o<l;o++){const c=a[o];e.addGroup(c.start,c.count,c.materialIndex)}return e}toJSON(){const t={metadata:{version:4.6,type:"BufferGeometry",generator:"BufferGeometry.toJSON"}};if(t.uuid=this.uuid,t.type=this.type,this.name!==""&&(t.name=this.name),Object.keys(this.userData).length>0&&(t.userData=this.userData),this.parameters!==void 0){const l=this.parameters;for(const c in l)l[c]!==void 0&&(t[c]=l[c]);return t}t.data={attributes:{}};const e=this.index;e!==null&&(t.data.index={type:e.array.constructor.name,array:Array.prototype.slice.call(e.array)});const n=this.attributes;for(const l in n){const c=n[l];t.data.attributes[l]=c.toJSON(t.data)}const i={};let s=!1;for(const l in this.morphAttributes){const c=this.morphAttributes[l],h=[];for(let u=0,d=c.length;u<d;u++){const f=c[u];h.push(f.toJSON(t.data))}h.length>0&&(i[l]=h,s=!0)}s&&(t.data.morphAttributes=i,t.data.morphTargetsRelative=this.morphTargetsRelative);const a=this.groups;a.length>0&&(t.data.groups=JSON.parse(JSON.stringify(a)));const o=this.boundingSphere;return o!==null&&(t.data.boundingSphere={center:o.center.toArray(),radius:o.radius}),t}clone(){return new this.constructor().copy(this)}copy(t){this.index=null,this.attributes={},this.morphAttributes={},this.groups=[],this.boundingBox=null,this.boundingSphere=null;const e={};this.name=t.name;const n=t.index;n!==null&&this.setIndex(n.clone(e));const i=t.attributes;for(const c in i){const h=i[c];this.setAttribute(c,h.clone(e))}const s=t.morphAttributes;for(const c in s){const h=[],u=s[c];for(let d=0,f=u.length;d<f;d++)h.push(u[d].clone(e));this.morphAttributes[c]=h}this.morphTargetsRelative=t.morphTargetsRelative;const a=t.groups;for(let c=0,h=a.length;c<h;c++){const u=a[c];this.addGroup(u.start,u.count,u.materialIndex)}const o=t.boundingBox;o!==null&&(this.boundingBox=o.clone());const l=t.boundingSphere;return l!==null&&(this.boundingSphere=l.clone()),this.drawRange.start=t.drawRange.start,this.drawRange.count=t.drawRange.count,this.userData=t.userData,this}dispose(){this.dispatchEvent({type:"dispose"})}}const cc=new It,Si=new ra,_r=new Ln,hc=new P,xr=new P,yr=new P,Mr=new P,Ia=new P,br=new P,uc=new P,Sr=new P;class Rt extends he{constructor(t=new ye,e=new ne){super(),this.isMesh=!0,this.type="Mesh",this.geometry=t,this.material=e,this.updateMorphTargets()}copy(t,e){return super.copy(t,e),t.morphTargetInfluences!==void 0&&(this.morphTargetInfluences=t.morphTargetInfluences.slice()),t.morphTargetDictionary!==void 0&&(this.morphTargetDictionary=Object.assign({},t.morphTargetDictionary)),this.material=Array.isArray(t.material)?t.material.slice():t.material,this.geometry=t.geometry,this}updateMorphTargets(){const e=this.geometry.morphAttributes,n=Object.keys(e);if(n.length>0){const i=e[n[0]];if(i!==void 0){this.morphTargetInfluences=[],this.morphTargetDictionary={};for(let s=0,a=i.length;s<a;s++){const o=i[s].name||String(s);this.morphTargetInfluences.push(0),this.morphTargetDictionary[o]=s}}}}getVertexPosition(t,e){const n=this.geometry,i=n.attributes.position,s=n.morphAttributes.position,a=n.morphTargetsRelative;e.fromBufferAttribute(i,t);const o=this.morphTargetInfluences;if(s&&o){br.set(0,0,0);for(let l=0,c=s.length;l<c;l++){const h=o[l],u=s[l];h!==0&&(Ia.fromBufferAttribute(u,t),a?br.addScaledVector(Ia,h):br.addScaledVector(Ia.sub(e),h))}e.add(br)}return e}raycast(t,e){const n=this.geometry,i=this.material,s=this.matrixWorld;i!==void 0&&(n.boundingSphere===null&&n.computeBoundingSphere(),_r.copy(n.boundingSphere),_r.applyMatrix4(s),Si.copy(t.ray).recast(t.near),!(_r.containsPoint(Si.origin)===!1&&(Si.intersectSphere(_r,hc)===null||Si.origin.distanceToSquared(hc)>(t.far-t.near)**2))&&(cc.copy(s).invert(),Si.copy(t.ray).applyMatrix4(cc),!(n.boundingBox!==null&&Si.intersectsBox(n.boundingBox)===!1)&&this._computeIntersections(t,e,Si)))}_computeIntersections(t,e,n){let i;const s=this.geometry,a=this.material,o=s.index,l=s.attributes.position,c=s.attributes.uv,h=s.attributes.uv1,u=s.attributes.normal,d=s.groups,f=s.drawRange;if(o!==null)if(Array.isArray(a))for(let m=0,v=d.length;m<v;m++){const g=d[m],p=a[g.materialIndex],x=Math.max(g.start,f.start),y=Math.min(o.count,Math.min(g.start+g.count,f.start+f.count));for(let _=x,I=y;_<I;_+=3){const E=o.getX(_),A=o.getX(_+1),C=o.getX(_+2);i=wr(this,p,t,n,c,h,u,E,A,C),i&&(i.faceIndex=Math.floor(_/3),i.face.materialIndex=g.materialIndex,e.push(i))}}else{const m=Math.max(0,f.start),v=Math.min(o.count,f.start+f.count);for(let g=m,p=v;g<p;g+=3){const x=o.getX(g),y=o.getX(g+1),_=o.getX(g+2);i=wr(this,a,t,n,c,h,u,x,y,_),i&&(i.faceIndex=Math.floor(g/3),e.push(i))}}else if(l!==void 0)if(Array.isArray(a))for(let m=0,v=d.length;m<v;m++){const g=d[m],p=a[g.materialIndex],x=Math.max(g.start,f.start),y=Math.min(l.count,Math.min(g.start+g.count,f.start+f.count));for(let _=x,I=y;_<I;_+=3){const E=_,A=_+1,C=_+2;i=wr(this,p,t,n,c,h,u,E,A,C),i&&(i.faceIndex=Math.floor(_/3),i.face.materialIndex=g.materialIndex,e.push(i))}}else{const m=Math.max(0,f.start),v=Math.min(l.count,f.start+f.count);for(let g=m,p=v;g<p;g+=3){const x=g,y=g+1,_=g+2;i=wr(this,a,t,n,c,h,u,x,y,_),i&&(i.faceIndex=Math.floor(g/3),e.push(i))}}}}function mf(r,t,e,n,i,s,a,o){let l;if(t.side===$e?l=n.intersectTriangle(a,s,i,!0,o):l=n.intersectTriangle(i,s,a,t.side===Zn,o),l===null)return null;Sr.copy(o),Sr.applyMatrix4(r.matrixWorld);const c=e.ray.origin.distanceTo(Sr);return c<e.near||c>e.far?null:{distance:c,point:Sr.clone(),object:r}}function wr(r,t,e,n,i,s,a,o,l,c){r.getVertexPosition(o,xr),r.getVertexPosition(l,yr),r.getVertexPosition(c,Mr);const h=mf(r,t,e,n,xr,yr,Mr,uc);if(h){const u=new P;bn.getBarycoord(uc,xr,yr,Mr,u),i&&(h.uv=bn.getInterpolatedAttribute(i,o,l,c,u,new nt)),s&&(h.uv1=bn.getInterpolatedAttribute(s,o,l,c,u,new nt)),a&&(h.normal=bn.getInterpolatedAttribute(a,o,l,c,u,new P),h.normal.dot(n.direction)>0&&h.normal.multiplyScalar(-1));const d={a:o,b:l,c,normal:new P,materialIndex:0};bn.getNormal(xr,yr,Mr,d.normal),h.face=d,h.barycoord=u}return h}class xe extends ye{constructor(t=1,e=1,n=1,i=1,s=1,a=1){super(),this.type="BoxGeometry",this.parameters={width:t,height:e,depth:n,widthSegments:i,heightSegments:s,depthSegments:a};const o=this;i=Math.floor(i),s=Math.floor(s),a=Math.floor(a);const l=[],c=[],h=[],u=[];let d=0,f=0;m("z","y","x",-1,-1,n,e,t,a,s,0),m("z","y","x",1,-1,n,e,-t,a,s,1),m("x","z","y",1,1,t,n,e,i,a,2),m("x","z","y",1,-1,t,n,-e,i,a,3),m("x","y","z",1,-1,t,e,n,i,s,4),m("x","y","z",-1,-1,t,e,-n,i,s,5),this.setIndex(l),this.setAttribute("position",new Vt(c,3)),this.setAttribute("normal",new Vt(h,3)),this.setAttribute("uv",new Vt(u,2));function m(v,g,p,x,y,_,I,E,A,C,b){const M=_/A,L=I/C,z=_/2,R=I/2,B=E/2,j=A+1,X=C+1;let Q=0,G=0;const it=new P;for(let lt=0;lt<X;lt++){const St=lt*L-R;for(let kt=0;kt<j;kt++){const ce=kt*M-z;it[v]=ce*x,it[g]=St*y,it[p]=B,c.push(it.x,it.y,it.z),it[v]=0,it[g]=0,it[p]=E>0?1:-1,h.push(it.x,it.y,it.z),u.push(kt/A),u.push(1-lt/C),Q+=1}}for(let lt=0;lt<C;lt++)for(let St=0;St<A;St++){const kt=d+St+j*lt,ce=d+St+j*(lt+1),Y=d+(St+1)+j*(lt+1),et=d+(St+1)+j*lt;l.push(kt,ce,et),l.push(ce,Y,et),G+=6}o.addGroup(f,G,b),f+=G,d+=Q}}copy(t){return super.copy(t),this.parameters=Object.assign({},t.parameters),this}static fromJSON(t){return new xe(t.width,t.height,t.depth,t.widthSegments,t.heightSegments,t.depthSegments)}}function ds(r){const t={};for(const e in r){t[e]={};for(const n in r[e]){const i=r[e][n];i&&(i.isColor||i.isMatrix3||i.isMatrix4||i.isVector2||i.isVector3||i.isVector4||i.isTexture||i.isQuaternion)?i.isRenderTargetTexture?(console.warn("UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms()."),t[e][n]=null):t[e][n]=i.clone():Array.isArray(i)?t[e][n]=i.slice():t[e][n]=i}}return t}function Ge(r){const t={};for(let e=0;e<r.length;e++){const n=ds(r[e]);for(const i in n)t[i]=n[i]}return t}function gf(r){const t=[];for(let e=0;e<r.length;e++)t.push(r[e].clone());return t}function su(r){const t=r.getRenderTarget();return t===null?r.outputColorSpace:t.isXRRenderTarget===!0?t.texture.colorSpace:Ht.workingColorSpace}const Js={clone:ds,merge:Ge};var vf=`void main() {
	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}`,_f=`void main() {
	gl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
}`;class Te extends Tn{static get type(){return"ShaderMaterial"}constructor(t){super(),this.isShaderMaterial=!0,this.defines={},this.uniforms={},this.uniformsGroups=[],this.vertexShader=vf,this.fragmentShader=_f,this.linewidth=1,this.wireframe=!1,this.wireframeLinewidth=1,this.fog=!1,this.lights=!1,this.clipping=!1,this.forceSinglePass=!0,this.extensions={clipCullDistance:!1,multiDraw:!1},this.defaultAttributeValues={color:[1,1,1],uv:[0,0],uv1:[0,0]},this.index0AttributeName=void 0,this.uniformsNeedUpdate=!1,this.glslVersion=null,t!==void 0&&this.setValues(t)}copy(t){return super.copy(t),this.fragmentShader=t.fragmentShader,this.vertexShader=t.vertexShader,this.uniforms=ds(t.uniforms),this.uniformsGroups=gf(t.uniformsGroups),this.defines=Object.assign({},t.defines),this.wireframe=t.wireframe,this.wireframeLinewidth=t.wireframeLinewidth,this.fog=t.fog,this.lights=t.lights,this.clipping=t.clipping,this.extensions=Object.assign({},t.extensions),this.glslVersion=t.glslVersion,this}toJSON(t){const e=super.toJSON(t);e.glslVersion=this.glslVersion,e.uniforms={};for(const i in this.uniforms){const a=this.uniforms[i].value;a&&a.isTexture?e.uniforms[i]={type:"t",value:a.toJSON(t).uuid}:a&&a.isColor?e.uniforms[i]={type:"c",value:a.getHex()}:a&&a.isVector2?e.uniforms[i]={type:"v2",value:a.toArray()}:a&&a.isVector3?e.uniforms[i]={type:"v3",value:a.toArray()}:a&&a.isVector4?e.uniforms[i]={type:"v4",value:a.toArray()}:a&&a.isMatrix3?e.uniforms[i]={type:"m3",value:a.toArray()}:a&&a.isMatrix4?e.uniforms[i]={type:"m4",value:a.toArray()}:e.uniforms[i]={value:a}}Object.keys(this.defines).length>0&&(e.defines=this.defines),e.vertexShader=this.vertexShader,e.fragmentShader=this.fragmentShader,e.lights=this.lights,e.clipping=this.clipping;const n={};for(const i in this.extensions)this.extensions[i]===!0&&(n[i]=!0);return Object.keys(n).length>0&&(e.extensions=n),e}}class ru extends he{constructor(){super(),this.isCamera=!0,this.type="Camera",this.matrixWorldInverse=new It,this.projectionMatrix=new It,this.projectionMatrixInverse=new It,this.coordinateSystem=Kn}copy(t,e){return super.copy(t,e),this.matrixWorldInverse.copy(t.matrixWorldInverse),this.projectionMatrix.copy(t.projectionMatrix),this.projectionMatrixInverse.copy(t.projectionMatrixInverse),this.coordinateSystem=t.coordinateSystem,this}getWorldDirection(t){return super.getWorldDirection(t).negate()}updateMatrixWorld(t){super.updateMatrixWorld(t),this.matrixWorldInverse.copy(this.matrixWorld).invert()}updateWorldMatrix(t,e){super.updateWorldMatrix(t,e),this.matrixWorldInverse.copy(this.matrixWorld).invert()}clone(){return new this.constructor().copy(this)}}const oi=new P,dc=new nt,fc=new nt;class ze extends ru{constructor(t=50,e=1,n=.1,i=2e3){super(),this.isPerspectiveCamera=!0,this.type="PerspectiveCamera",this.fov=t,this.zoom=1,this.near=n,this.far=i,this.focus=10,this.aspect=e,this.view=null,this.filmGauge=35,this.filmOffset=0,this.updateProjectionMatrix()}copy(t,e){return super.copy(t,e),this.fov=t.fov,this.zoom=t.zoom,this.near=t.near,this.far=t.far,this.focus=t.focus,this.aspect=t.aspect,this.view=t.view===null?null:Object.assign({},t.view),this.filmGauge=t.filmGauge,this.filmOffset=t.filmOffset,this}setFocalLength(t){const e=.5*this.getFilmHeight()/t;this.fov=us*2*Math.atan(e),this.updateProjectionMatrix()}getFocalLength(){const t=Math.tan(Vs*.5*this.fov);return .5*this.getFilmHeight()/t}getEffectiveFOV(){return us*2*Math.atan(Math.tan(Vs*.5*this.fov)/this.zoom)}getFilmWidth(){return this.filmGauge*Math.min(this.aspect,1)}getFilmHeight(){return this.filmGauge/Math.max(this.aspect,1)}getViewBounds(t,e,n){oi.set(-1,-1,.5).applyMatrix4(this.projectionMatrixInverse),e.set(oi.x,oi.y).multiplyScalar(-t/oi.z),oi.set(1,1,.5).applyMatrix4(this.projectionMatrixInverse),n.set(oi.x,oi.y).multiplyScalar(-t/oi.z)}getViewSize(t,e){return this.getViewBounds(t,dc,fc),e.subVectors(fc,dc)}setViewOffset(t,e,n,i,s,a){this.aspect=t/e,this.view===null&&(this.view={enabled:!0,fullWidth:1,fullHeight:1,offsetX:0,offsetY:0,width:1,height:1}),this.view.enabled=!0,this.view.fullWidth=t,this.view.fullHeight=e,this.view.offsetX=n,this.view.offsetY=i,this.view.width=s,this.view.height=a,this.updateProjectionMatrix()}clearViewOffset(){this.view!==null&&(this.view.enabled=!1),this.updateProjectionMatrix()}updateProjectionMatrix(){const t=this.near;let e=t*Math.tan(Vs*.5*this.fov)/this.zoom,n=2*e,i=this.aspect*n,s=-.5*i;const a=this.view;if(this.view!==null&&this.view.enabled){const l=a.fullWidth,c=a.fullHeight;s+=a.offsetX*i/l,e-=a.offsetY*n/c,i*=a.width/l,n*=a.height/c}const o=this.filmOffset;o!==0&&(s+=t*o/this.getFilmWidth()),this.projectionMatrix.makePerspective(s,s+i,e,e-n,t,this.far,this.coordinateSystem),this.projectionMatrixInverse.copy(this.projectionMatrix).invert()}toJSON(t){const e=super.toJSON(t);return e.object.fov=this.fov,e.object.zoom=this.zoom,e.object.near=this.near,e.object.far=this.far,e.object.focus=this.focus,e.object.aspect=this.aspect,this.view!==null&&(e.object.view=Object.assign({},this.view)),e.object.filmGauge=this.filmGauge,e.object.filmOffset=this.filmOffset,e}}const $i=-90,ji=1;class xf extends he{constructor(t,e,n){super(),this.type="CubeCamera",this.renderTarget=n,this.coordinateSystem=null,this.activeMipmapLevel=0;const i=new ze($i,ji,t,e);i.layers=this.layers,this.add(i);const s=new ze($i,ji,t,e);s.layers=this.layers,this.add(s);const a=new ze($i,ji,t,e);a.layers=this.layers,this.add(a);const o=new ze($i,ji,t,e);o.layers=this.layers,this.add(o);const l=new ze($i,ji,t,e);l.layers=this.layers,this.add(l);const c=new ze($i,ji,t,e);c.layers=this.layers,this.add(c)}updateCoordinateSystem(){const t=this.coordinateSystem,e=this.children.concat(),[n,i,s,a,o,l]=e;for(const c of e)this.remove(c);if(t===Kn)n.up.set(0,1,0),n.lookAt(1,0,0),i.up.set(0,1,0),i.lookAt(-1,0,0),s.up.set(0,0,-1),s.lookAt(0,1,0),a.up.set(0,0,1),a.lookAt(0,-1,0),o.up.set(0,1,0),o.lookAt(0,0,1),l.up.set(0,1,0),l.lookAt(0,0,-1);else if(t===jr)n.up.set(0,-1,0),n.lookAt(-1,0,0),i.up.set(0,-1,0),i.lookAt(1,0,0),s.up.set(0,0,1),s.lookAt(0,1,0),a.up.set(0,0,-1),a.lookAt(0,-1,0),o.up.set(0,-1,0),o.lookAt(0,0,1),l.up.set(0,-1,0),l.lookAt(0,0,-1);else throw new Error("THREE.CubeCamera.updateCoordinateSystem(): Invalid coordinate system: "+t);for(const c of e)this.add(c),c.updateMatrixWorld()}update(t,e){this.parent===null&&this.updateMatrixWorld();const{renderTarget:n,activeMipmapLevel:i}=this;this.coordinateSystem!==t.coordinateSystem&&(this.coordinateSystem=t.coordinateSystem,this.updateCoordinateSystem());const[s,a,o,l,c,h]=this.children,u=t.getRenderTarget(),d=t.getActiveCubeFace(),f=t.getActiveMipmapLevel(),m=t.xr.enabled;t.xr.enabled=!1;const v=n.texture.generateMipmaps;n.texture.generateMipmaps=!1,t.setRenderTarget(n,0,i),t.render(e,s),t.setRenderTarget(n,1,i),t.render(e,a),t.setRenderTarget(n,2,i),t.render(e,o),t.setRenderTarget(n,3,i),t.render(e,l),t.setRenderTarget(n,4,i),t.render(e,c),n.texture.generateMipmaps=v,t.setRenderTarget(n,5,i),t.render(e,h),t.setRenderTarget(u,d,f),t.xr.enabled=m,n.texture.needsPMREMUpdate=!0}}class au extends Ce{constructor(t,e,n,i,s,a,o,l,c,h){t=t!==void 0?t:[],e=e!==void 0?e:os,super(t,e,n,i,s,a,o,l,c,h),this.isCubeTexture=!0,this.flipY=!1}get images(){return this.image}set images(t){this.image=t}}class yf extends fn{constructor(t=1,e={}){super(t,t,e),this.isWebGLCubeRenderTarget=!0;const n={width:t,height:t,depth:1},i=[n,n,n,n,n,n];this.texture=new au(i,e.mapping,e.wrapS,e.wrapT,e.magFilter,e.minFilter,e.format,e.type,e.anisotropy,e.colorSpace),this.texture.isRenderTargetTexture=!0,this.texture.generateMipmaps=e.generateMipmaps!==void 0?e.generateMipmaps:!1,this.texture.minFilter=e.minFilter!==void 0?e.minFilter:tn}fromEquirectangularTexture(t,e){this.texture.type=e.type,this.texture.colorSpace=e.colorSpace,this.texture.generateMipmaps=e.generateMipmaps,this.texture.minFilter=e.minFilter,this.texture.magFilter=e.magFilter;const n={uniforms:{tEquirect:{value:null}},vertexShader:`

				varying vec3 vWorldDirection;

				vec3 transformDirection( in vec3 dir, in mat4 matrix ) {

					return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );

				}

				void main() {

					vWorldDirection = transformDirection( position, modelMatrix );

					#include <begin_vertex>
					#include <project_vertex>

				}
			`,fragmentShader:`

				uniform sampler2D tEquirect;

				varying vec3 vWorldDirection;

				#include <common>

				void main() {

					vec3 direction = normalize( vWorldDirection );

					vec2 sampleUV = equirectUv( direction );

					gl_FragColor = texture2D( tEquirect, sampleUV );

				}
			`},i=new xe(5,5,5),s=new Te({name:"CubemapFromEquirect",uniforms:ds(n.uniforms),vertexShader:n.vertexShader,fragmentShader:n.fragmentShader,side:$e,blending:$n});s.uniforms.tEquirect.value=e;const a=new Rt(i,s),o=e.minFilter;return e.minFilter===qn&&(e.minFilter=tn),new xf(1,10,this).update(t,a),e.minFilter=o,a.geometry.dispose(),a.material.dispose(),this}clear(t,e,n,i){const s=t.getRenderTarget();for(let a=0;a<6;a++)t.setRenderTarget(this,a),t.clear(e,n,i);t.setRenderTarget(s)}}const Da=new P,Mf=new P,bf=new Ut;class Ri{constructor(t=new P(1,0,0),e=0){this.isPlane=!0,this.normal=t,this.constant=e}set(t,e){return this.normal.copy(t),this.constant=e,this}setComponents(t,e,n,i){return this.normal.set(t,e,n),this.constant=i,this}setFromNormalAndCoplanarPoint(t,e){return this.normal.copy(t),this.constant=-e.dot(this.normal),this}setFromCoplanarPoints(t,e,n){const i=Da.subVectors(n,e).cross(Mf.subVectors(t,e)).normalize();return this.setFromNormalAndCoplanarPoint(i,t),this}copy(t){return this.normal.copy(t.normal),this.constant=t.constant,this}normalize(){const t=1/this.normal.length();return this.normal.multiplyScalar(t),this.constant*=t,this}negate(){return this.constant*=-1,this.normal.negate(),this}distanceToPoint(t){return this.normal.dot(t)+this.constant}distanceToSphere(t){return this.distanceToPoint(t.center)-t.radius}projectPoint(t,e){return e.copy(t).addScaledVector(this.normal,-this.distanceToPoint(t))}intersectLine(t,e){const n=t.delta(Da),i=this.normal.dot(n);if(i===0)return this.distanceToPoint(t.start)===0?e.copy(t.start):null;const s=-(t.start.dot(this.normal)+this.constant)/i;return s<0||s>1?null:e.copy(t.start).addScaledVector(n,s)}intersectsLine(t){const e=this.distanceToPoint(t.start),n=this.distanceToPoint(t.end);return e<0&&n>0||n<0&&e>0}intersectsBox(t){return t.intersectsPlane(this)}intersectsSphere(t){return t.intersectsPlane(this)}coplanarPoint(t){return t.copy(this.normal).multiplyScalar(-this.constant)}applyMatrix4(t,e){const n=e||bf.getNormalMatrix(t),i=this.coplanarPoint(Da).applyMatrix4(t),s=this.normal.applyMatrix3(n).normalize();return this.constant=-i.dot(s),this}translate(t){return this.constant-=t.dot(this.normal),this}equals(t){return t.normal.equals(this.normal)&&t.constant===this.constant}clone(){return new this.constructor().copy(this)}}const wi=new Ln,Tr=new P;class dl{constructor(t=new Ri,e=new Ri,n=new Ri,i=new Ri,s=new Ri,a=new Ri){this.planes=[t,e,n,i,s,a]}set(t,e,n,i,s,a){const o=this.planes;return o[0].copy(t),o[1].copy(e),o[2].copy(n),o[3].copy(i),o[4].copy(s),o[5].copy(a),this}copy(t){const e=this.planes;for(let n=0;n<6;n++)e[n].copy(t.planes[n]);return this}setFromProjectionMatrix(t,e=Kn){const n=this.planes,i=t.elements,s=i[0],a=i[1],o=i[2],l=i[3],c=i[4],h=i[5],u=i[6],d=i[7],f=i[8],m=i[9],v=i[10],g=i[11],p=i[12],x=i[13],y=i[14],_=i[15];if(n[0].setComponents(l-s,d-c,g-f,_-p).normalize(),n[1].setComponents(l+s,d+c,g+f,_+p).normalize(),n[2].setComponents(l+a,d+h,g+m,_+x).normalize(),n[3].setComponents(l-a,d-h,g-m,_-x).normalize(),n[4].setComponents(l-o,d-u,g-v,_-y).normalize(),e===Kn)n[5].setComponents(l+o,d+u,g+v,_+y).normalize();else if(e===jr)n[5].setComponents(o,u,v,y).normalize();else throw new Error("THREE.Frustum.setFromProjectionMatrix(): Invalid coordinate system: "+e);return this}intersectsObject(t){if(t.boundingSphere!==void 0)t.boundingSphere===null&&t.computeBoundingSphere(),wi.copy(t.boundingSphere).applyMatrix4(t.matrixWorld);else{const e=t.geometry;e.boundingSphere===null&&e.computeBoundingSphere(),wi.copy(e.boundingSphere).applyMatrix4(t.matrixWorld)}return this.intersectsSphere(wi)}intersectsSprite(t){return wi.center.set(0,0,0),wi.radius=.7071067811865476,wi.applyMatrix4(t.matrixWorld),this.intersectsSphere(wi)}intersectsSphere(t){const e=this.planes,n=t.center,i=-t.radius;for(let s=0;s<6;s++)if(e[s].distanceToPoint(n)<i)return!1;return!0}intersectsBox(t){const e=this.planes;for(let n=0;n<6;n++){const i=e[n];if(Tr.x=i.normal.x>0?t.max.x:t.min.x,Tr.y=i.normal.y>0?t.max.y:t.min.y,Tr.z=i.normal.z>0?t.max.z:t.min.z,i.distanceToPoint(Tr)<0)return!1}return!0}containsPoint(t){const e=this.planes;for(let n=0;n<6;n++)if(e[n].distanceToPoint(t)<0)return!1;return!0}clone(){return new this.constructor().copy(this)}}function ou(){let r=null,t=!1,e=null,n=null;function i(s,a){e(s,a),n=r.requestAnimationFrame(i)}return{start:function(){t!==!0&&e!==null&&(n=r.requestAnimationFrame(i),t=!0)},stop:function(){r.cancelAnimationFrame(n),t=!1},setAnimationLoop:function(s){e=s},setContext:function(s){r=s}}}function Sf(r){const t=new WeakMap;function e(o,l){const c=o.array,h=o.usage,u=c.byteLength,d=r.createBuffer();r.bindBuffer(l,d),r.bufferData(l,c,h),o.onUploadCallback();let f;if(c instanceof Float32Array)f=r.FLOAT;else if(c instanceof Uint16Array)o.isFloat16BufferAttribute?f=r.HALF_FLOAT:f=r.UNSIGNED_SHORT;else if(c instanceof Int16Array)f=r.SHORT;else if(c instanceof Uint32Array)f=r.UNSIGNED_INT;else if(c instanceof Int32Array)f=r.INT;else if(c instanceof Int8Array)f=r.BYTE;else if(c instanceof Uint8Array)f=r.UNSIGNED_BYTE;else if(c instanceof Uint8ClampedArray)f=r.UNSIGNED_BYTE;else throw new Error("THREE.WebGLAttributes: Unsupported buffer data format: "+c);return{buffer:d,type:f,bytesPerElement:c.BYTES_PER_ELEMENT,version:o.version,size:u}}function n(o,l,c){const h=l.array,u=l.updateRanges;if(r.bindBuffer(c,o),u.length===0)r.bufferSubData(c,0,h);else{u.sort((f,m)=>f.start-m.start);let d=0;for(let f=1;f<u.length;f++){const m=u[d],v=u[f];v.start<=m.start+m.count+1?m.count=Math.max(m.count,v.start+v.count-m.start):(++d,u[d]=v)}u.length=d+1;for(let f=0,m=u.length;f<m;f++){const v=u[f];r.bufferSubData(c,v.start*h.BYTES_PER_ELEMENT,h,v.start,v.count)}l.clearUpdateRanges()}l.onUploadCallback()}function i(o){return o.isInterleavedBufferAttribute&&(o=o.data),t.get(o)}function s(o){o.isInterleavedBufferAttribute&&(o=o.data);const l=t.get(o);l&&(r.deleteBuffer(l.buffer),t.delete(o))}function a(o,l){if(o.isInterleavedBufferAttribute&&(o=o.data),o.isGLBufferAttribute){const h=t.get(o);(!h||h.version<o.version)&&t.set(o,{buffer:o.buffer,type:o.type,bytesPerElement:o.elementSize,version:o.version});return}const c=t.get(o);if(c===void 0)t.set(o,e(o,l));else if(c.version<o.version){if(c.size!==o.array.byteLength)throw new Error("THREE.WebGLAttributes: The size of the buffer attribute's array buffer does not match the original size. Resizing buffer attributes is not supported.");n(c.buffer,o,l),c.version=o.version}}return{get:i,remove:s,update:a}}class We extends ye{constructor(t=1,e=1,n=1,i=1){super(),this.type="PlaneGeometry",this.parameters={width:t,height:e,widthSegments:n,heightSegments:i};const s=t/2,a=e/2,o=Math.floor(n),l=Math.floor(i),c=o+1,h=l+1,u=t/o,d=e/l,f=[],m=[],v=[],g=[];for(let p=0;p<h;p++){const x=p*d-a;for(let y=0;y<c;y++){const _=y*u-s;m.push(_,-x,0),v.push(0,0,1),g.push(y/o),g.push(1-p/l)}}for(let p=0;p<l;p++)for(let x=0;x<o;x++){const y=x+c*p,_=x+c*(p+1),I=x+1+c*(p+1),E=x+1+c*p;f.push(y,_,E),f.push(_,I,E)}this.setIndex(f),this.setAttribute("position",new Vt(m,3)),this.setAttribute("normal",new Vt(v,3)),this.setAttribute("uv",new Vt(g,2))}copy(t){return super.copy(t),this.parameters=Object.assign({},t.parameters),this}static fromJSON(t){return new We(t.width,t.height,t.widthSegments,t.heightSegments)}}var wf=`#ifdef USE_ALPHAHASH
	if ( diffuseColor.a < getAlphaHashThreshold( vPosition ) ) discard;
#endif`,Tf=`#ifdef USE_ALPHAHASH
	const float ALPHA_HASH_SCALE = 0.05;
	float hash2D( vec2 value ) {
		return fract( 1.0e4 * sin( 17.0 * value.x + 0.1 * value.y ) * ( 0.1 + abs( sin( 13.0 * value.y + value.x ) ) ) );
	}
	float hash3D( vec3 value ) {
		return hash2D( vec2( hash2D( value.xy ), value.z ) );
	}
	float getAlphaHashThreshold( vec3 position ) {
		float maxDeriv = max(
			length( dFdx( position.xyz ) ),
			length( dFdy( position.xyz ) )
		);
		float pixScale = 1.0 / ( ALPHA_HASH_SCALE * maxDeriv );
		vec2 pixScales = vec2(
			exp2( floor( log2( pixScale ) ) ),
			exp2( ceil( log2( pixScale ) ) )
		);
		vec2 alpha = vec2(
			hash3D( floor( pixScales.x * position.xyz ) ),
			hash3D( floor( pixScales.y * position.xyz ) )
		);
		float lerpFactor = fract( log2( pixScale ) );
		float x = ( 1.0 - lerpFactor ) * alpha.x + lerpFactor * alpha.y;
		float a = min( lerpFactor, 1.0 - lerpFactor );
		vec3 cases = vec3(
			x * x / ( 2.0 * a * ( 1.0 - a ) ),
			( x - 0.5 * a ) / ( 1.0 - a ),
			1.0 - ( ( 1.0 - x ) * ( 1.0 - x ) / ( 2.0 * a * ( 1.0 - a ) ) )
		);
		float threshold = ( x < ( 1.0 - a ) )
			? ( ( x < a ) ? cases.x : cases.y )
			: cases.z;
		return clamp( threshold , 1.0e-6, 1.0 );
	}
#endif`,Ef=`#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;
#endif`,Af=`#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`,Rf=`#ifdef USE_ALPHATEST
	#ifdef ALPHA_TO_COVERAGE
	diffuseColor.a = smoothstep( alphaTest, alphaTest + fwidth( diffuseColor.a ), diffuseColor.a );
	if ( diffuseColor.a == 0.0 ) discard;
	#else
	if ( diffuseColor.a < alphaTest ) discard;
	#endif
#endif`,Cf=`#ifdef USE_ALPHATEST
	uniform float alphaTest;
#endif`,Pf=`#ifdef USE_AOMAP
	float ambientOcclusion = ( texture2D( aoMap, vAoMapUv ).r - 1.0 ) * aoMapIntensity + 1.0;
	reflectedLight.indirectDiffuse *= ambientOcclusion;
	#if defined( USE_CLEARCOAT ) 
		clearcoatSpecularIndirect *= ambientOcclusion;
	#endif
	#if defined( USE_SHEEN ) 
		sheenSpecularIndirect *= ambientOcclusion;
	#endif
	#if defined( USE_ENVMAP ) && defined( STANDARD )
		float dotNV = saturate( dot( geometryNormal, geometryViewDir ) );
		reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, ambientOcclusion, material.roughness );
	#endif
#endif`,Lf=`#ifdef USE_AOMAP
	uniform sampler2D aoMap;
	uniform float aoMapIntensity;
#endif`,If=`#ifdef USE_BATCHING
	#if ! defined( GL_ANGLE_multi_draw )
	#define gl_DrawID _gl_DrawID
	uniform int _gl_DrawID;
	#endif
	uniform highp sampler2D batchingTexture;
	uniform highp usampler2D batchingIdTexture;
	mat4 getBatchingMatrix( const in float i ) {
		int size = textureSize( batchingTexture, 0 ).x;
		int j = int( i ) * 4;
		int x = j % size;
		int y = j / size;
		vec4 v1 = texelFetch( batchingTexture, ivec2( x, y ), 0 );
		vec4 v2 = texelFetch( batchingTexture, ivec2( x + 1, y ), 0 );
		vec4 v3 = texelFetch( batchingTexture, ivec2( x + 2, y ), 0 );
		vec4 v4 = texelFetch( batchingTexture, ivec2( x + 3, y ), 0 );
		return mat4( v1, v2, v3, v4 );
	}
	float getIndirectIndex( const in int i ) {
		int size = textureSize( batchingIdTexture, 0 ).x;
		int x = i % size;
		int y = i / size;
		return float( texelFetch( batchingIdTexture, ivec2( x, y ), 0 ).r );
	}
#endif
#ifdef USE_BATCHING_COLOR
	uniform sampler2D batchingColorTexture;
	vec3 getBatchingColor( const in float i ) {
		int size = textureSize( batchingColorTexture, 0 ).x;
		int j = int( i );
		int x = j % size;
		int y = j / size;
		return texelFetch( batchingColorTexture, ivec2( x, y ), 0 ).rgb;
	}
#endif`,Df=`#ifdef USE_BATCHING
	mat4 batchingMatrix = getBatchingMatrix( getIndirectIndex( gl_DrawID ) );
#endif`,Nf=`vec3 transformed = vec3( position );
#ifdef USE_ALPHAHASH
	vPosition = vec3( position );
#endif`,Uf=`vec3 objectNormal = vec3( normal );
#ifdef USE_TANGENT
	vec3 objectTangent = vec3( tangent.xyz );
#endif`,Ff=`float G_BlinnPhong_Implicit( ) {
	return 0.25;
}
float D_BlinnPhong( const in float shininess, const in float dotNH ) {
	return RECIPROCAL_PI * ( shininess * 0.5 + 1.0 ) * pow( dotNH, shininess );
}
vec3 BRDF_BlinnPhong( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in vec3 specularColor, const in float shininess ) {
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );
	vec3 F = F_Schlick( specularColor, 1.0, dotVH );
	float G = G_BlinnPhong_Implicit( );
	float D = D_BlinnPhong( shininess, dotNH );
	return F * ( G * D );
} // validated`,Of=`#ifdef USE_IRIDESCENCE
	const mat3 XYZ_TO_REC709 = mat3(
		 3.2404542, -0.9692660,  0.0556434,
		-1.5371385,  1.8760108, -0.2040259,
		-0.4985314,  0.0415560,  1.0572252
	);
	vec3 Fresnel0ToIor( vec3 fresnel0 ) {
		vec3 sqrtF0 = sqrt( fresnel0 );
		return ( vec3( 1.0 ) + sqrtF0 ) / ( vec3( 1.0 ) - sqrtF0 );
	}
	vec3 IorToFresnel0( vec3 transmittedIor, float incidentIor ) {
		return pow2( ( transmittedIor - vec3( incidentIor ) ) / ( transmittedIor + vec3( incidentIor ) ) );
	}
	float IorToFresnel0( float transmittedIor, float incidentIor ) {
		return pow2( ( transmittedIor - incidentIor ) / ( transmittedIor + incidentIor ));
	}
	vec3 evalSensitivity( float OPD, vec3 shift ) {
		float phase = 2.0 * PI * OPD * 1.0e-9;
		vec3 val = vec3( 5.4856e-13, 4.4201e-13, 5.2481e-13 );
		vec3 pos = vec3( 1.6810e+06, 1.7953e+06, 2.2084e+06 );
		vec3 var = vec3( 4.3278e+09, 9.3046e+09, 6.6121e+09 );
		vec3 xyz = val * sqrt( 2.0 * PI * var ) * cos( pos * phase + shift ) * exp( - pow2( phase ) * var );
		xyz.x += 9.7470e-14 * sqrt( 2.0 * PI * 4.5282e+09 ) * cos( 2.2399e+06 * phase + shift[ 0 ] ) * exp( - 4.5282e+09 * pow2( phase ) );
		xyz /= 1.0685e-7;
		vec3 rgb = XYZ_TO_REC709 * xyz;
		return rgb;
	}
	vec3 evalIridescence( float outsideIOR, float eta2, float cosTheta1, float thinFilmThickness, vec3 baseF0 ) {
		vec3 I;
		float iridescenceIOR = mix( outsideIOR, eta2, smoothstep( 0.0, 0.03, thinFilmThickness ) );
		float sinTheta2Sq = pow2( outsideIOR / iridescenceIOR ) * ( 1.0 - pow2( cosTheta1 ) );
		float cosTheta2Sq = 1.0 - sinTheta2Sq;
		if ( cosTheta2Sq < 0.0 ) {
			return vec3( 1.0 );
		}
		float cosTheta2 = sqrt( cosTheta2Sq );
		float R0 = IorToFresnel0( iridescenceIOR, outsideIOR );
		float R12 = F_Schlick( R0, 1.0, cosTheta1 );
		float T121 = 1.0 - R12;
		float phi12 = 0.0;
		if ( iridescenceIOR < outsideIOR ) phi12 = PI;
		float phi21 = PI - phi12;
		vec3 baseIOR = Fresnel0ToIor( clamp( baseF0, 0.0, 0.9999 ) );		vec3 R1 = IorToFresnel0( baseIOR, iridescenceIOR );
		vec3 R23 = F_Schlick( R1, 1.0, cosTheta2 );
		vec3 phi23 = vec3( 0.0 );
		if ( baseIOR[ 0 ] < iridescenceIOR ) phi23[ 0 ] = PI;
		if ( baseIOR[ 1 ] < iridescenceIOR ) phi23[ 1 ] = PI;
		if ( baseIOR[ 2 ] < iridescenceIOR ) phi23[ 2 ] = PI;
		float OPD = 2.0 * iridescenceIOR * thinFilmThickness * cosTheta2;
		vec3 phi = vec3( phi21 ) + phi23;
		vec3 R123 = clamp( R12 * R23, 1e-5, 0.9999 );
		vec3 r123 = sqrt( R123 );
		vec3 Rs = pow2( T121 ) * R23 / ( vec3( 1.0 ) - R123 );
		vec3 C0 = R12 + Rs;
		I = C0;
		vec3 Cm = Rs - T121;
		for ( int m = 1; m <= 2; ++ m ) {
			Cm *= r123;
			vec3 Sm = 2.0 * evalSensitivity( float( m ) * OPD, float( m ) * phi );
			I += Cm * Sm;
		}
		return max( I, vec3( 0.0 ) );
	}
#endif`,kf=`#ifdef USE_BUMPMAP
	uniform sampler2D bumpMap;
	uniform float bumpScale;
	vec2 dHdxy_fwd() {
		vec2 dSTdx = dFdx( vBumpMapUv );
		vec2 dSTdy = dFdy( vBumpMapUv );
		float Hll = bumpScale * texture2D( bumpMap, vBumpMapUv ).x;
		float dBx = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdx ).x - Hll;
		float dBy = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdy ).x - Hll;
		return vec2( dBx, dBy );
	}
	vec3 perturbNormalArb( vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection ) {
		vec3 vSigmaX = normalize( dFdx( surf_pos.xyz ) );
		vec3 vSigmaY = normalize( dFdy( surf_pos.xyz ) );
		vec3 vN = surf_norm;
		vec3 R1 = cross( vSigmaY, vN );
		vec3 R2 = cross( vN, vSigmaX );
		float fDet = dot( vSigmaX, R1 ) * faceDirection;
		vec3 vGrad = sign( fDet ) * ( dHdxy.x * R1 + dHdxy.y * R2 );
		return normalize( abs( fDet ) * surf_norm - vGrad );
	}
#endif`,Bf=`#if NUM_CLIPPING_PLANES > 0
	vec4 plane;
	#ifdef ALPHA_TO_COVERAGE
		float distanceToPlane, distanceGradient;
		float clipOpacity = 1.0;
		#pragma unroll_loop_start
		for ( int i = 0; i < UNION_CLIPPING_PLANES; i ++ ) {
			plane = clippingPlanes[ i ];
			distanceToPlane = - dot( vClipPosition, plane.xyz ) + plane.w;
			distanceGradient = fwidth( distanceToPlane ) / 2.0;
			clipOpacity *= smoothstep( - distanceGradient, distanceGradient, distanceToPlane );
			if ( clipOpacity == 0.0 ) discard;
		}
		#pragma unroll_loop_end
		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES
			float unionClipOpacity = 1.0;
			#pragma unroll_loop_start
			for ( int i = UNION_CLIPPING_PLANES; i < NUM_CLIPPING_PLANES; i ++ ) {
				plane = clippingPlanes[ i ];
				distanceToPlane = - dot( vClipPosition, plane.xyz ) + plane.w;
				distanceGradient = fwidth( distanceToPlane ) / 2.0;
				unionClipOpacity *= 1.0 - smoothstep( - distanceGradient, distanceGradient, distanceToPlane );
			}
			#pragma unroll_loop_end
			clipOpacity *= 1.0 - unionClipOpacity;
		#endif
		diffuseColor.a *= clipOpacity;
		if ( diffuseColor.a == 0.0 ) discard;
	#else
		#pragma unroll_loop_start
		for ( int i = 0; i < UNION_CLIPPING_PLANES; i ++ ) {
			plane = clippingPlanes[ i ];
			if ( dot( vClipPosition, plane.xyz ) > plane.w ) discard;
		}
		#pragma unroll_loop_end
		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES
			bool clipped = true;
			#pragma unroll_loop_start
			for ( int i = UNION_CLIPPING_PLANES; i < NUM_CLIPPING_PLANES; i ++ ) {
				plane = clippingPlanes[ i ];
				clipped = ( dot( vClipPosition, plane.xyz ) > plane.w ) && clipped;
			}
			#pragma unroll_loop_end
			if ( clipped ) discard;
		#endif
	#endif
#endif`,zf=`#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
	uniform vec4 clippingPlanes[ NUM_CLIPPING_PLANES ];
#endif`,Hf=`#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
#endif`,Vf=`#if NUM_CLIPPING_PLANES > 0
	vClipPosition = - mvPosition.xyz;
#endif`,Gf=`#if defined( USE_COLOR_ALPHA )
	diffuseColor *= vColor;
#elif defined( USE_COLOR )
	diffuseColor.rgb *= vColor;
#endif`,Wf=`#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR )
	varying vec3 vColor;
#endif`,Xf=`#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )
	varying vec3 vColor;
#endif`,qf=`#if defined( USE_COLOR_ALPHA )
	vColor = vec4( 1.0 );
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )
	vColor = vec3( 1.0 );
#endif
#ifdef USE_COLOR
	vColor *= color;
#endif
#ifdef USE_INSTANCING_COLOR
	vColor.xyz *= instanceColor.xyz;
#endif
#ifdef USE_BATCHING_COLOR
	vec3 batchingColor = getBatchingColor( getIndirectIndex( gl_DrawID ) );
	vColor.xyz *= batchingColor.xyz;
#endif`,Yf=`#define PI 3.141592653589793
#define PI2 6.283185307179586
#define PI_HALF 1.5707963267948966
#define RECIPROCAL_PI 0.3183098861837907
#define RECIPROCAL_PI2 0.15915494309189535
#define EPSILON 1e-6
#ifndef saturate
#define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
#define whiteComplement( a ) ( 1.0 - saturate( a ) )
float pow2( const in float x ) { return x*x; }
vec3 pow2( const in vec3 x ) { return x*x; }
float pow3( const in float x ) { return x*x*x; }
float pow4( const in float x ) { float x2 = x*x; return x2*x2; }
float max3( const in vec3 v ) { return max( max( v.x, v.y ), v.z ); }
float average( const in vec3 v ) { return dot( v, vec3( 0.3333333 ) ); }
highp float rand( const in vec2 uv ) {
	const highp float a = 12.9898, b = 78.233, c = 43758.5453;
	highp float dt = dot( uv.xy, vec2( a,b ) ), sn = mod( dt, PI );
	return fract( sin( sn ) * c );
}
#ifdef HIGH_PRECISION
	float precisionSafeLength( vec3 v ) { return length( v ); }
#else
	float precisionSafeLength( vec3 v ) {
		float maxComponent = max3( abs( v ) );
		return length( v / maxComponent ) * maxComponent;
	}
#endif
struct IncidentLight {
	vec3 color;
	vec3 direction;
	bool visible;
};
struct ReflectedLight {
	vec3 directDiffuse;
	vec3 directSpecular;
	vec3 indirectDiffuse;
	vec3 indirectSpecular;
};
#ifdef USE_ALPHAHASH
	varying vec3 vPosition;
#endif
vec3 transformDirection( in vec3 dir, in mat4 matrix ) {
	return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );
}
vec3 inverseTransformDirection( in vec3 dir, in mat4 matrix ) {
	return normalize( ( vec4( dir, 0.0 ) * matrix ).xyz );
}
mat3 transposeMat3( const in mat3 m ) {
	mat3 tmp;
	tmp[ 0 ] = vec3( m[ 0 ].x, m[ 1 ].x, m[ 2 ].x );
	tmp[ 1 ] = vec3( m[ 0 ].y, m[ 1 ].y, m[ 2 ].y );
	tmp[ 2 ] = vec3( m[ 0 ].z, m[ 1 ].z, m[ 2 ].z );
	return tmp;
}
bool isPerspectiveMatrix( mat4 m ) {
	return m[ 2 ][ 3 ] == - 1.0;
}
vec2 equirectUv( in vec3 dir ) {
	float u = atan( dir.z, dir.x ) * RECIPROCAL_PI2 + 0.5;
	float v = asin( clamp( dir.y, - 1.0, 1.0 ) ) * RECIPROCAL_PI + 0.5;
	return vec2( u, v );
}
vec3 BRDF_Lambert( const in vec3 diffuseColor ) {
	return RECIPROCAL_PI * diffuseColor;
}
vec3 F_Schlick( const in vec3 f0, const in float f90, const in float dotVH ) {
	float fresnel = exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH );
	return f0 * ( 1.0 - fresnel ) + ( f90 * fresnel );
}
float F_Schlick( const in float f0, const in float f90, const in float dotVH ) {
	float fresnel = exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH );
	return f0 * ( 1.0 - fresnel ) + ( f90 * fresnel );
} // validated`,Kf=`#ifdef ENVMAP_TYPE_CUBE_UV
	#define cubeUV_minMipLevel 4.0
	#define cubeUV_minTileSize 16.0
	float getFace( vec3 direction ) {
		vec3 absDirection = abs( direction );
		float face = - 1.0;
		if ( absDirection.x > absDirection.z ) {
			if ( absDirection.x > absDirection.y )
				face = direction.x > 0.0 ? 0.0 : 3.0;
			else
				face = direction.y > 0.0 ? 1.0 : 4.0;
		} else {
			if ( absDirection.z > absDirection.y )
				face = direction.z > 0.0 ? 2.0 : 5.0;
			else
				face = direction.y > 0.0 ? 1.0 : 4.0;
		}
		return face;
	}
	vec2 getUV( vec3 direction, float face ) {
		vec2 uv;
		if ( face == 0.0 ) {
			uv = vec2( direction.z, direction.y ) / abs( direction.x );
		} else if ( face == 1.0 ) {
			uv = vec2( - direction.x, - direction.z ) / abs( direction.y );
		} else if ( face == 2.0 ) {
			uv = vec2( - direction.x, direction.y ) / abs( direction.z );
		} else if ( face == 3.0 ) {
			uv = vec2( - direction.z, direction.y ) / abs( direction.x );
		} else if ( face == 4.0 ) {
			uv = vec2( - direction.x, direction.z ) / abs( direction.y );
		} else {
			uv = vec2( direction.x, direction.y ) / abs( direction.z );
		}
		return 0.5 * ( uv + 1.0 );
	}
	vec3 bilinearCubeUV( sampler2D envMap, vec3 direction, float mipInt ) {
		float face = getFace( direction );
		float filterInt = max( cubeUV_minMipLevel - mipInt, 0.0 );
		mipInt = max( mipInt, cubeUV_minMipLevel );
		float faceSize = exp2( mipInt );
		highp vec2 uv = getUV( direction, face ) * ( faceSize - 2.0 ) + 1.0;
		if ( face > 2.0 ) {
			uv.y += faceSize;
			face -= 3.0;
		}
		uv.x += face * faceSize;
		uv.x += filterInt * 3.0 * cubeUV_minTileSize;
		uv.y += 4.0 * ( exp2( CUBEUV_MAX_MIP ) - faceSize );
		uv.x *= CUBEUV_TEXEL_WIDTH;
		uv.y *= CUBEUV_TEXEL_HEIGHT;
		#ifdef texture2DGradEXT
			return texture2DGradEXT( envMap, uv, vec2( 0.0 ), vec2( 0.0 ) ).rgb;
		#else
			return texture2D( envMap, uv ).rgb;
		#endif
	}
	#define cubeUV_r0 1.0
	#define cubeUV_m0 - 2.0
	#define cubeUV_r1 0.8
	#define cubeUV_m1 - 1.0
	#define cubeUV_r4 0.4
	#define cubeUV_m4 2.0
	#define cubeUV_r5 0.305
	#define cubeUV_m5 3.0
	#define cubeUV_r6 0.21
	#define cubeUV_m6 4.0
	float roughnessToMip( float roughness ) {
		float mip = 0.0;
		if ( roughness >= cubeUV_r1 ) {
			mip = ( cubeUV_r0 - roughness ) * ( cubeUV_m1 - cubeUV_m0 ) / ( cubeUV_r0 - cubeUV_r1 ) + cubeUV_m0;
		} else if ( roughness >= cubeUV_r4 ) {
			mip = ( cubeUV_r1 - roughness ) * ( cubeUV_m4 - cubeUV_m1 ) / ( cubeUV_r1 - cubeUV_r4 ) + cubeUV_m1;
		} else if ( roughness >= cubeUV_r5 ) {
			mip = ( cubeUV_r4 - roughness ) * ( cubeUV_m5 - cubeUV_m4 ) / ( cubeUV_r4 - cubeUV_r5 ) + cubeUV_m4;
		} else if ( roughness >= cubeUV_r6 ) {
			mip = ( cubeUV_r5 - roughness ) * ( cubeUV_m6 - cubeUV_m5 ) / ( cubeUV_r5 - cubeUV_r6 ) + cubeUV_m5;
		} else {
			mip = - 2.0 * log2( 1.16 * roughness );		}
		return mip;
	}
	vec4 textureCubeUV( sampler2D envMap, vec3 sampleDir, float roughness ) {
		float mip = clamp( roughnessToMip( roughness ), cubeUV_m0, CUBEUV_MAX_MIP );
		float mipF = fract( mip );
		float mipInt = floor( mip );
		vec3 color0 = bilinearCubeUV( envMap, sampleDir, mipInt );
		if ( mipF == 0.0 ) {
			return vec4( color0, 1.0 );
		} else {
			vec3 color1 = bilinearCubeUV( envMap, sampleDir, mipInt + 1.0 );
			return vec4( mix( color0, color1, mipF ), 1.0 );
		}
	}
#endif`,$f=`vec3 transformedNormal = objectNormal;
#ifdef USE_TANGENT
	vec3 transformedTangent = objectTangent;
#endif
#ifdef USE_BATCHING
	mat3 bm = mat3( batchingMatrix );
	transformedNormal /= vec3( dot( bm[ 0 ], bm[ 0 ] ), dot( bm[ 1 ], bm[ 1 ] ), dot( bm[ 2 ], bm[ 2 ] ) );
	transformedNormal = bm * transformedNormal;
	#ifdef USE_TANGENT
		transformedTangent = bm * transformedTangent;
	#endif
#endif
#ifdef USE_INSTANCING
	mat3 im = mat3( instanceMatrix );
	transformedNormal /= vec3( dot( im[ 0 ], im[ 0 ] ), dot( im[ 1 ], im[ 1 ] ), dot( im[ 2 ], im[ 2 ] ) );
	transformedNormal = im * transformedNormal;
	#ifdef USE_TANGENT
		transformedTangent = im * transformedTangent;
	#endif
#endif
transformedNormal = normalMatrix * transformedNormal;
#ifdef FLIP_SIDED
	transformedNormal = - transformedNormal;
#endif
#ifdef USE_TANGENT
	transformedTangent = ( modelViewMatrix * vec4( transformedTangent, 0.0 ) ).xyz;
	#ifdef FLIP_SIDED
		transformedTangent = - transformedTangent;
	#endif
#endif`,jf=`#ifdef USE_DISPLACEMENTMAP
	uniform sampler2D displacementMap;
	uniform float displacementScale;
	uniform float displacementBias;
#endif`,Zf=`#ifdef USE_DISPLACEMENTMAP
	transformed += normalize( objectNormal ) * ( texture2D( displacementMap, vDisplacementMapUv ).x * displacementScale + displacementBias );
#endif`,Jf=`#ifdef USE_EMISSIVEMAP
	vec4 emissiveColor = texture2D( emissiveMap, vEmissiveMapUv );
	#ifdef DECODE_VIDEO_TEXTURE_EMISSIVE
		emissiveColor = sRGBTransferEOTF( emissiveColor );
	#endif
	totalEmissiveRadiance *= emissiveColor.rgb;
#endif`,Qf=`#ifdef USE_EMISSIVEMAP
	uniform sampler2D emissiveMap;
#endif`,tp="gl_FragColor = linearToOutputTexel( gl_FragColor );",ep=`vec4 LinearTransferOETF( in vec4 value ) {
	return value;
}
vec4 sRGBTransferEOTF( in vec4 value ) {
	return vec4( mix( pow( value.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), value.rgb * 0.0773993808, vec3( lessThanEqual( value.rgb, vec3( 0.04045 ) ) ) ), value.a );
}
vec4 sRGBTransferOETF( in vec4 value ) {
	return vec4( mix( pow( value.rgb, vec3( 0.41666 ) ) * 1.055 - vec3( 0.055 ), value.rgb * 12.92, vec3( lessThanEqual( value.rgb, vec3( 0.0031308 ) ) ) ), value.a );
}`,np=`#ifdef USE_ENVMAP
	#ifdef ENV_WORLDPOS
		vec3 cameraToFrag;
		if ( isOrthographic ) {
			cameraToFrag = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
		} else {
			cameraToFrag = normalize( vWorldPosition - cameraPosition );
		}
		vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
		#ifdef ENVMAP_MODE_REFLECTION
			vec3 reflectVec = reflect( cameraToFrag, worldNormal );
		#else
			vec3 reflectVec = refract( cameraToFrag, worldNormal, refractionRatio );
		#endif
	#else
		vec3 reflectVec = vReflect;
	#endif
	#ifdef ENVMAP_TYPE_CUBE
		vec4 envColor = textureCube( envMap, envMapRotation * vec3( flipEnvMap * reflectVec.x, reflectVec.yz ) );
	#else
		vec4 envColor = vec4( 0.0 );
	#endif
	#ifdef ENVMAP_BLENDING_MULTIPLY
		outgoingLight = mix( outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity );
	#elif defined( ENVMAP_BLENDING_MIX )
		outgoingLight = mix( outgoingLight, envColor.xyz, specularStrength * reflectivity );
	#elif defined( ENVMAP_BLENDING_ADD )
		outgoingLight += envColor.xyz * specularStrength * reflectivity;
	#endif
#endif`,ip=`#ifdef USE_ENVMAP
	uniform float envMapIntensity;
	uniform float flipEnvMap;
	uniform mat3 envMapRotation;
	#ifdef ENVMAP_TYPE_CUBE
		uniform samplerCube envMap;
	#else
		uniform sampler2D envMap;
	#endif
	
#endif`,sp=`#ifdef USE_ENVMAP
	uniform float reflectivity;
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		varying vec3 vWorldPosition;
		uniform float refractionRatio;
	#else
		varying vec3 vReflect;
	#endif
#endif`,rp=`#ifdef USE_ENVMAP
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		
		varying vec3 vWorldPosition;
	#else
		varying vec3 vReflect;
		uniform float refractionRatio;
	#endif
#endif`,ap=`#ifdef USE_ENVMAP
	#ifdef ENV_WORLDPOS
		vWorldPosition = worldPosition.xyz;
	#else
		vec3 cameraToVertex;
		if ( isOrthographic ) {
			cameraToVertex = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
		} else {
			cameraToVertex = normalize( worldPosition.xyz - cameraPosition );
		}
		vec3 worldNormal = inverseTransformDirection( transformedNormal, viewMatrix );
		#ifdef ENVMAP_MODE_REFLECTION
			vReflect = reflect( cameraToVertex, worldNormal );
		#else
			vReflect = refract( cameraToVertex, worldNormal, refractionRatio );
		#endif
	#endif
#endif`,op=`#ifdef USE_FOG
	vFogDepth = - mvPosition.z;
#endif`,lp=`#ifdef USE_FOG
	varying float vFogDepth;
#endif`,cp=`#ifdef USE_FOG
	#ifdef FOG_EXP2
		float fogFactor = 1.0 - exp( - fogDensity * fogDensity * vFogDepth * vFogDepth );
	#else
		float fogFactor = smoothstep( fogNear, fogFar, vFogDepth );
	#endif
	gl_FragColor.rgb = mix( gl_FragColor.rgb, fogColor, fogFactor );
#endif`,hp=`#ifdef USE_FOG
	uniform vec3 fogColor;
	varying float vFogDepth;
	#ifdef FOG_EXP2
		uniform float fogDensity;
	#else
		uniform float fogNear;
		uniform float fogFar;
	#endif
#endif`,up=`#ifdef USE_GRADIENTMAP
	uniform sampler2D gradientMap;
#endif
vec3 getGradientIrradiance( vec3 normal, vec3 lightDirection ) {
	float dotNL = dot( normal, lightDirection );
	vec2 coord = vec2( dotNL * 0.5 + 0.5, 0.0 );
	#ifdef USE_GRADIENTMAP
		return vec3( texture2D( gradientMap, coord ).r );
	#else
		vec2 fw = fwidth( coord ) * 0.5;
		return mix( vec3( 0.7 ), vec3( 1.0 ), smoothstep( 0.7 - fw.x, 0.7 + fw.x, coord.x ) );
	#endif
}`,dp=`#ifdef USE_LIGHTMAP
	uniform sampler2D lightMap;
	uniform float lightMapIntensity;
#endif`,fp=`LambertMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularStrength = specularStrength;`,pp=`varying vec3 vViewPosition;
struct LambertMaterial {
	vec3 diffuseColor;
	float specularStrength;
};
void RE_Direct_Lambert( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Lambert( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Lambert
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Lambert`,mp=`uniform bool receiveShadow;
uniform vec3 ambientLightColor;
#if defined( USE_LIGHT_PROBES )
	uniform vec3 lightProbe[ 9 ];
#endif
vec3 shGetIrradianceAt( in vec3 normal, in vec3 shCoefficients[ 9 ] ) {
	float x = normal.x, y = normal.y, z = normal.z;
	vec3 result = shCoefficients[ 0 ] * 0.886227;
	result += shCoefficients[ 1 ] * 2.0 * 0.511664 * y;
	result += shCoefficients[ 2 ] * 2.0 * 0.511664 * z;
	result += shCoefficients[ 3 ] * 2.0 * 0.511664 * x;
	result += shCoefficients[ 4 ] * 2.0 * 0.429043 * x * y;
	result += shCoefficients[ 5 ] * 2.0 * 0.429043 * y * z;
	result += shCoefficients[ 6 ] * ( 0.743125 * z * z - 0.247708 );
	result += shCoefficients[ 7 ] * 2.0 * 0.429043 * x * z;
	result += shCoefficients[ 8 ] * 0.429043 * ( x * x - y * y );
	return result;
}
vec3 getLightProbeIrradiance( const in vec3 lightProbe[ 9 ], const in vec3 normal ) {
	vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
	vec3 irradiance = shGetIrradianceAt( worldNormal, lightProbe );
	return irradiance;
}
vec3 getAmbientLightIrradiance( const in vec3 ambientLightColor ) {
	vec3 irradiance = ambientLightColor;
	return irradiance;
}
float getDistanceAttenuation( const in float lightDistance, const in float cutoffDistance, const in float decayExponent ) {
	float distanceFalloff = 1.0 / max( pow( lightDistance, decayExponent ), 0.01 );
	if ( cutoffDistance > 0.0 ) {
		distanceFalloff *= pow2( saturate( 1.0 - pow4( lightDistance / cutoffDistance ) ) );
	}
	return distanceFalloff;
}
float getSpotAttenuation( const in float coneCosine, const in float penumbraCosine, const in float angleCosine ) {
	return smoothstep( coneCosine, penumbraCosine, angleCosine );
}
#if NUM_DIR_LIGHTS > 0
	struct DirectionalLight {
		vec3 direction;
		vec3 color;
	};
	uniform DirectionalLight directionalLights[ NUM_DIR_LIGHTS ];
	void getDirectionalLightInfo( const in DirectionalLight directionalLight, out IncidentLight light ) {
		light.color = directionalLight.color;
		light.direction = directionalLight.direction;
		light.visible = true;
	}
#endif
#if NUM_POINT_LIGHTS > 0
	struct PointLight {
		vec3 position;
		vec3 color;
		float distance;
		float decay;
	};
	uniform PointLight pointLights[ NUM_POINT_LIGHTS ];
	void getPointLightInfo( const in PointLight pointLight, const in vec3 geometryPosition, out IncidentLight light ) {
		vec3 lVector = pointLight.position - geometryPosition;
		light.direction = normalize( lVector );
		float lightDistance = length( lVector );
		light.color = pointLight.color;
		light.color *= getDistanceAttenuation( lightDistance, pointLight.distance, pointLight.decay );
		light.visible = ( light.color != vec3( 0.0 ) );
	}
#endif
#if NUM_SPOT_LIGHTS > 0
	struct SpotLight {
		vec3 position;
		vec3 direction;
		vec3 color;
		float distance;
		float decay;
		float coneCos;
		float penumbraCos;
	};
	uniform SpotLight spotLights[ NUM_SPOT_LIGHTS ];
	void getSpotLightInfo( const in SpotLight spotLight, const in vec3 geometryPosition, out IncidentLight light ) {
		vec3 lVector = spotLight.position - geometryPosition;
		light.direction = normalize( lVector );
		float angleCos = dot( light.direction, spotLight.direction );
		float spotAttenuation = getSpotAttenuation( spotLight.coneCos, spotLight.penumbraCos, angleCos );
		if ( spotAttenuation > 0.0 ) {
			float lightDistance = length( lVector );
			light.color = spotLight.color * spotAttenuation;
			light.color *= getDistanceAttenuation( lightDistance, spotLight.distance, spotLight.decay );
			light.visible = ( light.color != vec3( 0.0 ) );
		} else {
			light.color = vec3( 0.0 );
			light.visible = false;
		}
	}
#endif
#if NUM_RECT_AREA_LIGHTS > 0
	struct RectAreaLight {
		vec3 color;
		vec3 position;
		vec3 halfWidth;
		vec3 halfHeight;
	};
	uniform sampler2D ltc_1;	uniform sampler2D ltc_2;
	uniform RectAreaLight rectAreaLights[ NUM_RECT_AREA_LIGHTS ];
#endif
#if NUM_HEMI_LIGHTS > 0
	struct HemisphereLight {
		vec3 direction;
		vec3 skyColor;
		vec3 groundColor;
	};
	uniform HemisphereLight hemisphereLights[ NUM_HEMI_LIGHTS ];
	vec3 getHemisphereLightIrradiance( const in HemisphereLight hemiLight, const in vec3 normal ) {
		float dotNL = dot( normal, hemiLight.direction );
		float hemiDiffuseWeight = 0.5 * dotNL + 0.5;
		vec3 irradiance = mix( hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight );
		return irradiance;
	}
#endif`,gp=`#ifdef USE_ENVMAP
	vec3 getIBLIrradiance( const in vec3 normal ) {
		#ifdef ENVMAP_TYPE_CUBE_UV
			vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, envMapRotation * worldNormal, 1.0 );
			return PI * envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
	vec3 getIBLRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness ) {
		#ifdef ENVMAP_TYPE_CUBE_UV
			vec3 reflectVec = reflect( - viewDir, normal );
			reflectVec = normalize( mix( reflectVec, normal, roughness * roughness) );
			reflectVec = inverseTransformDirection( reflectVec, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, envMapRotation * reflectVec, roughness );
			return envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
	#ifdef USE_ANISOTROPY
		vec3 getIBLAnisotropyRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness, const in vec3 bitangent, const in float anisotropy ) {
			#ifdef ENVMAP_TYPE_CUBE_UV
				vec3 bentNormal = cross( bitangent, viewDir );
				bentNormal = normalize( cross( bentNormal, bitangent ) );
				bentNormal = normalize( mix( bentNormal, normal, pow2( pow2( 1.0 - anisotropy * ( 1.0 - roughness ) ) ) ) );
				return getIBLRadiance( viewDir, bentNormal, roughness );
			#else
				return vec3( 0.0 );
			#endif
		}
	#endif
#endif`,vp=`ToonMaterial material;
material.diffuseColor = diffuseColor.rgb;`,_p=`varying vec3 vViewPosition;
struct ToonMaterial {
	vec3 diffuseColor;
};
void RE_Direct_Toon( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	vec3 irradiance = getGradientIrradiance( geometryNormal, directLight.direction ) * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Toon( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Toon
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Toon`,xp=`BlinnPhongMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularColor = specular;
material.specularShininess = shininess;
material.specularStrength = specularStrength;`,yp=`varying vec3 vViewPosition;
struct BlinnPhongMaterial {
	vec3 diffuseColor;
	vec3 specularColor;
	float specularShininess;
	float specularStrength;
};
void RE_Direct_BlinnPhong( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
	reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong( directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess ) * material.specularStrength;
}
void RE_IndirectDiffuse_BlinnPhong( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_BlinnPhong
#define RE_IndirectDiffuse		RE_IndirectDiffuse_BlinnPhong`,Mp=`PhysicalMaterial material;
material.diffuseColor = diffuseColor.rgb * ( 1.0 - metalnessFactor );
vec3 dxy = max( abs( dFdx( nonPerturbedNormal ) ), abs( dFdy( nonPerturbedNormal ) ) );
float geometryRoughness = max( max( dxy.x, dxy.y ), dxy.z );
material.roughness = max( roughnessFactor, 0.0525 );material.roughness += geometryRoughness;
material.roughness = min( material.roughness, 1.0 );
#ifdef IOR
	material.ior = ior;
	#ifdef USE_SPECULAR
		float specularIntensityFactor = specularIntensity;
		vec3 specularColorFactor = specularColor;
		#ifdef USE_SPECULAR_COLORMAP
			specularColorFactor *= texture2D( specularColorMap, vSpecularColorMapUv ).rgb;
		#endif
		#ifdef USE_SPECULAR_INTENSITYMAP
			specularIntensityFactor *= texture2D( specularIntensityMap, vSpecularIntensityMapUv ).a;
		#endif
		material.specularF90 = mix( specularIntensityFactor, 1.0, metalnessFactor );
	#else
		float specularIntensityFactor = 1.0;
		vec3 specularColorFactor = vec3( 1.0 );
		material.specularF90 = 1.0;
	#endif
	material.specularColor = mix( min( pow2( ( material.ior - 1.0 ) / ( material.ior + 1.0 ) ) * specularColorFactor, vec3( 1.0 ) ) * specularIntensityFactor, diffuseColor.rgb, metalnessFactor );
#else
	material.specularColor = mix( vec3( 0.04 ), diffuseColor.rgb, metalnessFactor );
	material.specularF90 = 1.0;
#endif
#ifdef USE_CLEARCOAT
	material.clearcoat = clearcoat;
	material.clearcoatRoughness = clearcoatRoughness;
	material.clearcoatF0 = vec3( 0.04 );
	material.clearcoatF90 = 1.0;
	#ifdef USE_CLEARCOATMAP
		material.clearcoat *= texture2D( clearcoatMap, vClearcoatMapUv ).x;
	#endif
	#ifdef USE_CLEARCOAT_ROUGHNESSMAP
		material.clearcoatRoughness *= texture2D( clearcoatRoughnessMap, vClearcoatRoughnessMapUv ).y;
	#endif
	material.clearcoat = saturate( material.clearcoat );	material.clearcoatRoughness = max( material.clearcoatRoughness, 0.0525 );
	material.clearcoatRoughness += geometryRoughness;
	material.clearcoatRoughness = min( material.clearcoatRoughness, 1.0 );
#endif
#ifdef USE_DISPERSION
	material.dispersion = dispersion;
#endif
#ifdef USE_IRIDESCENCE
	material.iridescence = iridescence;
	material.iridescenceIOR = iridescenceIOR;
	#ifdef USE_IRIDESCENCEMAP
		material.iridescence *= texture2D( iridescenceMap, vIridescenceMapUv ).r;
	#endif
	#ifdef USE_IRIDESCENCE_THICKNESSMAP
		material.iridescenceThickness = (iridescenceThicknessMaximum - iridescenceThicknessMinimum) * texture2D( iridescenceThicknessMap, vIridescenceThicknessMapUv ).g + iridescenceThicknessMinimum;
	#else
		material.iridescenceThickness = iridescenceThicknessMaximum;
	#endif
#endif
#ifdef USE_SHEEN
	material.sheenColor = sheenColor;
	#ifdef USE_SHEEN_COLORMAP
		material.sheenColor *= texture2D( sheenColorMap, vSheenColorMapUv ).rgb;
	#endif
	material.sheenRoughness = clamp( sheenRoughness, 0.07, 1.0 );
	#ifdef USE_SHEEN_ROUGHNESSMAP
		material.sheenRoughness *= texture2D( sheenRoughnessMap, vSheenRoughnessMapUv ).a;
	#endif
#endif
#ifdef USE_ANISOTROPY
	#ifdef USE_ANISOTROPYMAP
		mat2 anisotropyMat = mat2( anisotropyVector.x, anisotropyVector.y, - anisotropyVector.y, anisotropyVector.x );
		vec3 anisotropyPolar = texture2D( anisotropyMap, vAnisotropyMapUv ).rgb;
		vec2 anisotropyV = anisotropyMat * normalize( 2.0 * anisotropyPolar.rg - vec2( 1.0 ) ) * anisotropyPolar.b;
	#else
		vec2 anisotropyV = anisotropyVector;
	#endif
	material.anisotropy = length( anisotropyV );
	if( material.anisotropy == 0.0 ) {
		anisotropyV = vec2( 1.0, 0.0 );
	} else {
		anisotropyV /= material.anisotropy;
		material.anisotropy = saturate( material.anisotropy );
	}
	material.alphaT = mix( pow2( material.roughness ), 1.0, pow2( material.anisotropy ) );
	material.anisotropyT = tbn[ 0 ] * anisotropyV.x + tbn[ 1 ] * anisotropyV.y;
	material.anisotropyB = tbn[ 1 ] * anisotropyV.x - tbn[ 0 ] * anisotropyV.y;
#endif`,bp=`struct PhysicalMaterial {
	vec3 diffuseColor;
	float roughness;
	vec3 specularColor;
	float specularF90;
	float dispersion;
	#ifdef USE_CLEARCOAT
		float clearcoat;
		float clearcoatRoughness;
		vec3 clearcoatF0;
		float clearcoatF90;
	#endif
	#ifdef USE_IRIDESCENCE
		float iridescence;
		float iridescenceIOR;
		float iridescenceThickness;
		vec3 iridescenceFresnel;
		vec3 iridescenceF0;
	#endif
	#ifdef USE_SHEEN
		vec3 sheenColor;
		float sheenRoughness;
	#endif
	#ifdef IOR
		float ior;
	#endif
	#ifdef USE_TRANSMISSION
		float transmission;
		float transmissionAlpha;
		float thickness;
		float attenuationDistance;
		vec3 attenuationColor;
	#endif
	#ifdef USE_ANISOTROPY
		float anisotropy;
		float alphaT;
		vec3 anisotropyT;
		vec3 anisotropyB;
	#endif
};
vec3 clearcoatSpecularDirect = vec3( 0.0 );
vec3 clearcoatSpecularIndirect = vec3( 0.0 );
vec3 sheenSpecularDirect = vec3( 0.0 );
vec3 sheenSpecularIndirect = vec3(0.0 );
vec3 Schlick_to_F0( const in vec3 f, const in float f90, const in float dotVH ) {
    float x = clamp( 1.0 - dotVH, 0.0, 1.0 );
    float x2 = x * x;
    float x5 = clamp( x * x2 * x2, 0.0, 0.9999 );
    return ( f - vec3( f90 ) * x5 ) / ( 1.0 - x5 );
}
float V_GGX_SmithCorrelated( const in float alpha, const in float dotNL, const in float dotNV ) {
	float a2 = pow2( alpha );
	float gv = dotNL * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNV ) );
	float gl = dotNV * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNL ) );
	return 0.5 / max( gv + gl, EPSILON );
}
float D_GGX( const in float alpha, const in float dotNH ) {
	float a2 = pow2( alpha );
	float denom = pow2( dotNH ) * ( a2 - 1.0 ) + 1.0;
	return RECIPROCAL_PI * a2 / pow2( denom );
}
#ifdef USE_ANISOTROPY
	float V_GGX_SmithCorrelated_Anisotropic( const in float alphaT, const in float alphaB, const in float dotTV, const in float dotBV, const in float dotTL, const in float dotBL, const in float dotNV, const in float dotNL ) {
		float gv = dotNL * length( vec3( alphaT * dotTV, alphaB * dotBV, dotNV ) );
		float gl = dotNV * length( vec3( alphaT * dotTL, alphaB * dotBL, dotNL ) );
		float v = 0.5 / ( gv + gl );
		return saturate(v);
	}
	float D_GGX_Anisotropic( const in float alphaT, const in float alphaB, const in float dotNH, const in float dotTH, const in float dotBH ) {
		float a2 = alphaT * alphaB;
		highp vec3 v = vec3( alphaB * dotTH, alphaT * dotBH, a2 * dotNH );
		highp float v2 = dot( v, v );
		float w2 = a2 / v2;
		return RECIPROCAL_PI * a2 * pow2 ( w2 );
	}
#endif
#ifdef USE_CLEARCOAT
	vec3 BRDF_GGX_Clearcoat( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material) {
		vec3 f0 = material.clearcoatF0;
		float f90 = material.clearcoatF90;
		float roughness = material.clearcoatRoughness;
		float alpha = pow2( roughness );
		vec3 halfDir = normalize( lightDir + viewDir );
		float dotNL = saturate( dot( normal, lightDir ) );
		float dotNV = saturate( dot( normal, viewDir ) );
		float dotNH = saturate( dot( normal, halfDir ) );
		float dotVH = saturate( dot( viewDir, halfDir ) );
		vec3 F = F_Schlick( f0, f90, dotVH );
		float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
		float D = D_GGX( alpha, dotNH );
		return F * ( V * D );
	}
#endif
vec3 BRDF_GGX( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material ) {
	vec3 f0 = material.specularColor;
	float f90 = material.specularF90;
	float roughness = material.roughness;
	float alpha = pow2( roughness );
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );
	vec3 F = F_Schlick( f0, f90, dotVH );
	#ifdef USE_IRIDESCENCE
		F = mix( F, material.iridescenceFresnel, material.iridescence );
	#endif
	#ifdef USE_ANISOTROPY
		float dotTL = dot( material.anisotropyT, lightDir );
		float dotTV = dot( material.anisotropyT, viewDir );
		float dotTH = dot( material.anisotropyT, halfDir );
		float dotBL = dot( material.anisotropyB, lightDir );
		float dotBV = dot( material.anisotropyB, viewDir );
		float dotBH = dot( material.anisotropyB, halfDir );
		float V = V_GGX_SmithCorrelated_Anisotropic( material.alphaT, alpha, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL );
		float D = D_GGX_Anisotropic( material.alphaT, alpha, dotNH, dotTH, dotBH );
	#else
		float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
		float D = D_GGX( alpha, dotNH );
	#endif
	return F * ( V * D );
}
vec2 LTC_Uv( const in vec3 N, const in vec3 V, const in float roughness ) {
	const float LUT_SIZE = 64.0;
	const float LUT_SCALE = ( LUT_SIZE - 1.0 ) / LUT_SIZE;
	const float LUT_BIAS = 0.5 / LUT_SIZE;
	float dotNV = saturate( dot( N, V ) );
	vec2 uv = vec2( roughness, sqrt( 1.0 - dotNV ) );
	uv = uv * LUT_SCALE + LUT_BIAS;
	return uv;
}
float LTC_ClippedSphereFormFactor( const in vec3 f ) {
	float l = length( f );
	return max( ( l * l + f.z ) / ( l + 1.0 ), 0.0 );
}
vec3 LTC_EdgeVectorFormFactor( const in vec3 v1, const in vec3 v2 ) {
	float x = dot( v1, v2 );
	float y = abs( x );
	float a = 0.8543985 + ( 0.4965155 + 0.0145206 * y ) * y;
	float b = 3.4175940 + ( 4.1616724 + y ) * y;
	float v = a / b;
	float theta_sintheta = ( x > 0.0 ) ? v : 0.5 * inversesqrt( max( 1.0 - x * x, 1e-7 ) ) - v;
	return cross( v1, v2 ) * theta_sintheta;
}
vec3 LTC_Evaluate( const in vec3 N, const in vec3 V, const in vec3 P, const in mat3 mInv, const in vec3 rectCoords[ 4 ] ) {
	vec3 v1 = rectCoords[ 1 ] - rectCoords[ 0 ];
	vec3 v2 = rectCoords[ 3 ] - rectCoords[ 0 ];
	vec3 lightNormal = cross( v1, v2 );
	if( dot( lightNormal, P - rectCoords[ 0 ] ) < 0.0 ) return vec3( 0.0 );
	vec3 T1, T2;
	T1 = normalize( V - N * dot( V, N ) );
	T2 = - cross( N, T1 );
	mat3 mat = mInv * transposeMat3( mat3( T1, T2, N ) );
	vec3 coords[ 4 ];
	coords[ 0 ] = mat * ( rectCoords[ 0 ] - P );
	coords[ 1 ] = mat * ( rectCoords[ 1 ] - P );
	coords[ 2 ] = mat * ( rectCoords[ 2 ] - P );
	coords[ 3 ] = mat * ( rectCoords[ 3 ] - P );
	coords[ 0 ] = normalize( coords[ 0 ] );
	coords[ 1 ] = normalize( coords[ 1 ] );
	coords[ 2 ] = normalize( coords[ 2 ] );
	coords[ 3 ] = normalize( coords[ 3 ] );
	vec3 vectorFormFactor = vec3( 0.0 );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 0 ], coords[ 1 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 1 ], coords[ 2 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 2 ], coords[ 3 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 3 ], coords[ 0 ] );
	float result = LTC_ClippedSphereFormFactor( vectorFormFactor );
	return vec3( result );
}
#if defined( USE_SHEEN )
float D_Charlie( float roughness, float dotNH ) {
	float alpha = pow2( roughness );
	float invAlpha = 1.0 / alpha;
	float cos2h = dotNH * dotNH;
	float sin2h = max( 1.0 - cos2h, 0.0078125 );
	return ( 2.0 + invAlpha ) * pow( sin2h, invAlpha * 0.5 ) / ( 2.0 * PI );
}
float V_Neubelt( float dotNV, float dotNL ) {
	return saturate( 1.0 / ( 4.0 * ( dotNL + dotNV - dotNL * dotNV ) ) );
}
vec3 BRDF_Sheen( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, vec3 sheenColor, const in float sheenRoughness ) {
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float D = D_Charlie( sheenRoughness, dotNH );
	float V = V_Neubelt( dotNV, dotNL );
	return sheenColor * ( D * V );
}
#endif
float IBLSheenBRDF( const in vec3 normal, const in vec3 viewDir, const in float roughness ) {
	float dotNV = saturate( dot( normal, viewDir ) );
	float r2 = roughness * roughness;
	float a = roughness < 0.25 ? -339.2 * r2 + 161.4 * roughness - 25.9 : -8.48 * r2 + 14.3 * roughness - 9.95;
	float b = roughness < 0.25 ? 44.0 * r2 - 23.7 * roughness + 3.26 : 1.97 * r2 - 3.27 * roughness + 0.72;
	float DG = exp( a * dotNV + b ) + ( roughness < 0.25 ? 0.0 : 0.1 * ( roughness - 0.25 ) );
	return saturate( DG * RECIPROCAL_PI );
}
vec2 DFGApprox( const in vec3 normal, const in vec3 viewDir, const in float roughness ) {
	float dotNV = saturate( dot( normal, viewDir ) );
	const vec4 c0 = vec4( - 1, - 0.0275, - 0.572, 0.022 );
	const vec4 c1 = vec4( 1, 0.0425, 1.04, - 0.04 );
	vec4 r = roughness * c0 + c1;
	float a004 = min( r.x * r.x, exp2( - 9.28 * dotNV ) ) * r.x + r.y;
	vec2 fab = vec2( - 1.04, 1.04 ) * a004 + r.zw;
	return fab;
}
vec3 EnvironmentBRDF( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness ) {
	vec2 fab = DFGApprox( normal, viewDir, roughness );
	return specularColor * fab.x + specularF90 * fab.y;
}
#ifdef USE_IRIDESCENCE
void computeMultiscatteringIridescence( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float iridescence, const in vec3 iridescenceF0, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter ) {
#else
void computeMultiscattering( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter ) {
#endif
	vec2 fab = DFGApprox( normal, viewDir, roughness );
	#ifdef USE_IRIDESCENCE
		vec3 Fr = mix( specularColor, iridescenceF0, iridescence );
	#else
		vec3 Fr = specularColor;
	#endif
	vec3 FssEss = Fr * fab.x + specularF90 * fab.y;
	float Ess = fab.x + fab.y;
	float Ems = 1.0 - Ess;
	vec3 Favg = Fr + ( 1.0 - Fr ) * 0.047619;	vec3 Fms = FssEss * Favg / ( 1.0 - Ems * Favg );
	singleScatter += FssEss;
	multiScatter += Fms * Ems;
}
#if NUM_RECT_AREA_LIGHTS > 0
	void RE_Direct_RectArea_Physical( const in RectAreaLight rectAreaLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
		vec3 normal = geometryNormal;
		vec3 viewDir = geometryViewDir;
		vec3 position = geometryPosition;
		vec3 lightPos = rectAreaLight.position;
		vec3 halfWidth = rectAreaLight.halfWidth;
		vec3 halfHeight = rectAreaLight.halfHeight;
		vec3 lightColor = rectAreaLight.color;
		float roughness = material.roughness;
		vec3 rectCoords[ 4 ];
		rectCoords[ 0 ] = lightPos + halfWidth - halfHeight;		rectCoords[ 1 ] = lightPos - halfWidth - halfHeight;
		rectCoords[ 2 ] = lightPos - halfWidth + halfHeight;
		rectCoords[ 3 ] = lightPos + halfWidth + halfHeight;
		vec2 uv = LTC_Uv( normal, viewDir, roughness );
		vec4 t1 = texture2D( ltc_1, uv );
		vec4 t2 = texture2D( ltc_2, uv );
		mat3 mInv = mat3(
			vec3( t1.x, 0, t1.y ),
			vec3(    0, 1,    0 ),
			vec3( t1.z, 0, t1.w )
		);
		vec3 fresnel = ( material.specularColor * t2.x + ( vec3( 1.0 ) - material.specularColor ) * t2.y );
		reflectedLight.directSpecular += lightColor * fresnel * LTC_Evaluate( normal, viewDir, position, mInv, rectCoords );
		reflectedLight.directDiffuse += lightColor * material.diffuseColor * LTC_Evaluate( normal, viewDir, position, mat3( 1.0 ), rectCoords );
	}
#endif
void RE_Direct_Physical( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	#ifdef USE_CLEARCOAT
		float dotNLcc = saturate( dot( geometryClearcoatNormal, directLight.direction ) );
		vec3 ccIrradiance = dotNLcc * directLight.color;
		clearcoatSpecularDirect += ccIrradiance * BRDF_GGX_Clearcoat( directLight.direction, geometryViewDir, geometryClearcoatNormal, material );
	#endif
	#ifdef USE_SHEEN
		sheenSpecularDirect += irradiance * BRDF_Sheen( directLight.direction, geometryViewDir, geometryNormal, material.sheenColor, material.sheenRoughness );
	#endif
	reflectedLight.directSpecular += irradiance * BRDF_GGX( directLight.direction, geometryViewDir, geometryNormal, material );
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Physical( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectSpecular_Physical( const in vec3 radiance, const in vec3 irradiance, const in vec3 clearcoatRadiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight) {
	#ifdef USE_CLEARCOAT
		clearcoatSpecularIndirect += clearcoatRadiance * EnvironmentBRDF( geometryClearcoatNormal, geometryViewDir, material.clearcoatF0, material.clearcoatF90, material.clearcoatRoughness );
	#endif
	#ifdef USE_SHEEN
		sheenSpecularIndirect += irradiance * material.sheenColor * IBLSheenBRDF( geometryNormal, geometryViewDir, material.sheenRoughness );
	#endif
	vec3 singleScattering = vec3( 0.0 );
	vec3 multiScattering = vec3( 0.0 );
	vec3 cosineWeightedIrradiance = irradiance * RECIPROCAL_PI;
	#ifdef USE_IRIDESCENCE
		computeMultiscatteringIridescence( geometryNormal, geometryViewDir, material.specularColor, material.specularF90, material.iridescence, material.iridescenceFresnel, material.roughness, singleScattering, multiScattering );
	#else
		computeMultiscattering( geometryNormal, geometryViewDir, material.specularColor, material.specularF90, material.roughness, singleScattering, multiScattering );
	#endif
	vec3 totalScattering = singleScattering + multiScattering;
	vec3 diffuse = material.diffuseColor * ( 1.0 - max( max( totalScattering.r, totalScattering.g ), totalScattering.b ) );
	reflectedLight.indirectSpecular += radiance * singleScattering;
	reflectedLight.indirectSpecular += multiScattering * cosineWeightedIrradiance;
	reflectedLight.indirectDiffuse += diffuse * cosineWeightedIrradiance;
}
#define RE_Direct				RE_Direct_Physical
#define RE_Direct_RectArea		RE_Direct_RectArea_Physical
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Physical
#define RE_IndirectSpecular		RE_IndirectSpecular_Physical
float computeSpecularOcclusion( const in float dotNV, const in float ambientOcclusion, const in float roughness ) {
	return saturate( pow( dotNV + ambientOcclusion, exp2( - 16.0 * roughness - 1.0 ) ) - 1.0 + ambientOcclusion );
}`,Sp=`
vec3 geometryPosition = - vViewPosition;
vec3 geometryNormal = normal;
vec3 geometryViewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );
vec3 geometryClearcoatNormal = vec3( 0.0 );
#ifdef USE_CLEARCOAT
	geometryClearcoatNormal = clearcoatNormal;
#endif
#ifdef USE_IRIDESCENCE
	float dotNVi = saturate( dot( normal, geometryViewDir ) );
	if ( material.iridescenceThickness == 0.0 ) {
		material.iridescence = 0.0;
	} else {
		material.iridescence = saturate( material.iridescence );
	}
	if ( material.iridescence > 0.0 ) {
		material.iridescenceFresnel = evalIridescence( 1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor );
		material.iridescenceF0 = Schlick_to_F0( material.iridescenceFresnel, 1.0, dotNVi );
	}
#endif
IncidentLight directLight;
#if ( NUM_POINT_LIGHTS > 0 ) && defined( RE_Direct )
	PointLight pointLight;
	#if defined( USE_SHADOWMAP ) && NUM_POINT_LIGHT_SHADOWS > 0
	PointLightShadow pointLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHTS; i ++ ) {
		pointLight = pointLights[ i ];
		getPointLightInfo( pointLight, geometryPosition, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS )
		pointLightShadow = pointLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getPointShadow( pointShadowMap[ i ], pointLightShadow.shadowMapSize, pointLightShadow.shadowIntensity, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[ i ], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_SPOT_LIGHTS > 0 ) && defined( RE_Direct )
	SpotLight spotLight;
	vec4 spotColor;
	vec3 spotLightCoord;
	bool inSpotLightMap;
	#if defined( USE_SHADOWMAP ) && NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHTS; i ++ ) {
		spotLight = spotLights[ i ];
		getSpotLightInfo( spotLight, geometryPosition, directLight );
		#if ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
		#define SPOT_LIGHT_MAP_INDEX UNROLLED_LOOP_INDEX
		#elif ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
		#define SPOT_LIGHT_MAP_INDEX NUM_SPOT_LIGHT_MAPS
		#else
		#define SPOT_LIGHT_MAP_INDEX ( UNROLLED_LOOP_INDEX - NUM_SPOT_LIGHT_SHADOWS + NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
		#endif
		#if ( SPOT_LIGHT_MAP_INDEX < NUM_SPOT_LIGHT_MAPS )
			spotLightCoord = vSpotLightCoord[ i ].xyz / vSpotLightCoord[ i ].w;
			inSpotLightMap = all( lessThan( abs( spotLightCoord * 2. - 1. ), vec3( 1.0 ) ) );
			spotColor = texture2D( spotLightMap[ SPOT_LIGHT_MAP_INDEX ], spotLightCoord.xy );
			directLight.color = inSpotLightMap ? directLight.color * spotColor.rgb : directLight.color;
		#endif
		#undef SPOT_LIGHT_MAP_INDEX
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
		spotLightShadow = spotLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( spotShadowMap[ i ], spotLightShadow.shadowMapSize, spotLightShadow.shadowIntensity, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_DIR_LIGHTS > 0 ) && defined( RE_Direct )
	DirectionalLight directionalLight;
	#if defined( USE_SHADOWMAP ) && NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHTS; i ++ ) {
		directionalLight = directionalLights[ i ];
		getDirectionalLightInfo( directionalLight, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_DIR_LIGHT_SHADOWS )
		directionalLightShadow = directionalLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( directionalShadowMap[ i ], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowIntensity, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_RECT_AREA_LIGHTS > 0 ) && defined( RE_Direct_RectArea )
	RectAreaLight rectAreaLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_RECT_AREA_LIGHTS; i ++ ) {
		rectAreaLight = rectAreaLights[ i ];
		RE_Direct_RectArea( rectAreaLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if defined( RE_IndirectDiffuse )
	vec3 iblIrradiance = vec3( 0.0 );
	vec3 irradiance = getAmbientLightIrradiance( ambientLightColor );
	#if defined( USE_LIGHT_PROBES )
		irradiance += getLightProbeIrradiance( lightProbe, geometryNormal );
	#endif
	#if ( NUM_HEMI_LIGHTS > 0 )
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_HEMI_LIGHTS; i ++ ) {
			irradiance += getHemisphereLightIrradiance( hemisphereLights[ i ], geometryNormal );
		}
		#pragma unroll_loop_end
	#endif
#endif
#if defined( RE_IndirectSpecular )
	vec3 radiance = vec3( 0.0 );
	vec3 clearcoatRadiance = vec3( 0.0 );
#endif`,wp=`#if defined( RE_IndirectDiffuse )
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
		irradiance += lightMapIrradiance;
	#endif
	#if defined( USE_ENVMAP ) && defined( STANDARD ) && defined( ENVMAP_TYPE_CUBE_UV )
		iblIrradiance += getIBLIrradiance( geometryNormal );
	#endif
#endif
#if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )
	#ifdef USE_ANISOTROPY
		radiance += getIBLAnisotropyRadiance( geometryViewDir, geometryNormal, material.roughness, material.anisotropyB, material.anisotropy );
	#else
		radiance += getIBLRadiance( geometryViewDir, geometryNormal, material.roughness );
	#endif
	#ifdef USE_CLEARCOAT
		clearcoatRadiance += getIBLRadiance( geometryViewDir, geometryClearcoatNormal, material.clearcoatRoughness );
	#endif
#endif`,Tp=`#if defined( RE_IndirectDiffuse )
	RE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
#endif
#if defined( RE_IndirectSpecular )
	RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
#endif`,Ep=`#if defined( USE_LOGDEPTHBUF )
	gl_FragDepth = vIsPerspective == 0.0 ? gl_FragCoord.z : log2( vFragDepth ) * logDepthBufFC * 0.5;
#endif`,Ap=`#if defined( USE_LOGDEPTHBUF )
	uniform float logDepthBufFC;
	varying float vFragDepth;
	varying float vIsPerspective;
#endif`,Rp=`#ifdef USE_LOGDEPTHBUF
	varying float vFragDepth;
	varying float vIsPerspective;
#endif`,Cp=`#ifdef USE_LOGDEPTHBUF
	vFragDepth = 1.0 + gl_Position.w;
	vIsPerspective = float( isPerspectiveMatrix( projectionMatrix ) );
#endif`,Pp=`#ifdef USE_MAP
	vec4 sampledDiffuseColor = texture2D( map, vMapUv );
	#ifdef DECODE_VIDEO_TEXTURE
		sampledDiffuseColor = sRGBTransferEOTF( sampledDiffuseColor );
	#endif
	diffuseColor *= sampledDiffuseColor;
#endif`,Lp=`#ifdef USE_MAP
	uniform sampler2D map;
#endif`,Ip=`#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
	#if defined( USE_POINTS_UV )
		vec2 uv = vUv;
	#else
		vec2 uv = ( uvTransform * vec3( gl_PointCoord.x, 1.0 - gl_PointCoord.y, 1 ) ).xy;
	#endif
#endif
#ifdef USE_MAP
	diffuseColor *= texture2D( map, uv );
#endif
#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, uv ).g;
#endif`,Dp=`#if defined( USE_POINTS_UV )
	varying vec2 vUv;
#else
	#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
		uniform mat3 uvTransform;
	#endif
#endif
#ifdef USE_MAP
	uniform sampler2D map;
#endif
#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`,Np=`float metalnessFactor = metalness;
#ifdef USE_METALNESSMAP
	vec4 texelMetalness = texture2D( metalnessMap, vMetalnessMapUv );
	metalnessFactor *= texelMetalness.b;
#endif`,Up=`#ifdef USE_METALNESSMAP
	uniform sampler2D metalnessMap;
#endif`,Fp=`#ifdef USE_INSTANCING_MORPH
	float morphTargetInfluences[ MORPHTARGETS_COUNT ];
	float morphTargetBaseInfluence = texelFetch( morphTexture, ivec2( 0, gl_InstanceID ), 0 ).r;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		morphTargetInfluences[i] =  texelFetch( morphTexture, ivec2( i + 1, gl_InstanceID ), 0 ).r;
	}
#endif`,Op=`#if defined( USE_MORPHCOLORS )
	vColor *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		#if defined( USE_COLOR_ALPHA )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ) * morphTargetInfluences[ i ];
		#elif defined( USE_COLOR )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ).rgb * morphTargetInfluences[ i ];
		#endif
	}
#endif`,kp=`#ifdef USE_MORPHNORMALS
	objectNormal *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		if ( morphTargetInfluences[ i ] != 0.0 ) objectNormal += getMorph( gl_VertexID, i, 1 ).xyz * morphTargetInfluences[ i ];
	}
#endif`,Bp=`#ifdef USE_MORPHTARGETS
	#ifndef USE_INSTANCING_MORPH
		uniform float morphTargetBaseInfluence;
		uniform float morphTargetInfluences[ MORPHTARGETS_COUNT ];
	#endif
	uniform sampler2DArray morphTargetsTexture;
	uniform ivec2 morphTargetsTextureSize;
	vec4 getMorph( const in int vertexIndex, const in int morphTargetIndex, const in int offset ) {
		int texelIndex = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
		int y = texelIndex / morphTargetsTextureSize.x;
		int x = texelIndex - y * morphTargetsTextureSize.x;
		ivec3 morphUV = ivec3( x, y, morphTargetIndex );
		return texelFetch( morphTargetsTexture, morphUV, 0 );
	}
#endif`,zp=`#ifdef USE_MORPHTARGETS
	transformed *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		if ( morphTargetInfluences[ i ] != 0.0 ) transformed += getMorph( gl_VertexID, i, 0 ).xyz * morphTargetInfluences[ i ];
	}
#endif`,Hp=`float faceDirection = gl_FrontFacing ? 1.0 : - 1.0;
#ifdef FLAT_SHADED
	vec3 fdx = dFdx( vViewPosition );
	vec3 fdy = dFdy( vViewPosition );
	vec3 normal = normalize( cross( fdx, fdy ) );
#else
	vec3 normal = normalize( vNormal );
	#ifdef DOUBLE_SIDED
		normal *= faceDirection;
	#endif
#endif
#if defined( USE_NORMALMAP_TANGENTSPACE ) || defined( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY )
	#ifdef USE_TANGENT
		mat3 tbn = mat3( normalize( vTangent ), normalize( vBitangent ), normal );
	#else
		mat3 tbn = getTangentFrame( - vViewPosition, normal,
		#if defined( USE_NORMALMAP )
			vNormalMapUv
		#elif defined( USE_CLEARCOAT_NORMALMAP )
			vClearcoatNormalMapUv
		#else
			vUv
		#endif
		);
	#endif
	#if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )
		tbn[0] *= faceDirection;
		tbn[1] *= faceDirection;
	#endif
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	#ifdef USE_TANGENT
		mat3 tbn2 = mat3( normalize( vTangent ), normalize( vBitangent ), normal );
	#else
		mat3 tbn2 = getTangentFrame( - vViewPosition, normal, vClearcoatNormalMapUv );
	#endif
	#if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )
		tbn2[0] *= faceDirection;
		tbn2[1] *= faceDirection;
	#endif
#endif
vec3 nonPerturbedNormal = normal;`,Vp=`#ifdef USE_NORMALMAP_OBJECTSPACE
	normal = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
	#ifdef FLIP_SIDED
		normal = - normal;
	#endif
	#ifdef DOUBLE_SIDED
		normal = normal * faceDirection;
	#endif
	normal = normalize( normalMatrix * normal );
#elif defined( USE_NORMALMAP_TANGENTSPACE )
	vec3 mapN = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
	mapN.xy *= normalScale;
	normal = normalize( tbn * mapN );
#elif defined( USE_BUMPMAP )
	normal = perturbNormalArb( - vViewPosition, normal, dHdxy_fwd(), faceDirection );
#endif`,Gp=`#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`,Wp=`#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`,Xp=`#ifndef FLAT_SHADED
	vNormal = normalize( transformedNormal );
	#ifdef USE_TANGENT
		vTangent = normalize( transformedTangent );
		vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );
	#endif
#endif`,qp=`#ifdef USE_NORMALMAP
	uniform sampler2D normalMap;
	uniform vec2 normalScale;
#endif
#ifdef USE_NORMALMAP_OBJECTSPACE
	uniform mat3 normalMatrix;
#endif
#if ! defined ( USE_TANGENT ) && ( defined ( USE_NORMALMAP_TANGENTSPACE ) || defined ( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY ) )
	mat3 getTangentFrame( vec3 eye_pos, vec3 surf_norm, vec2 uv ) {
		vec3 q0 = dFdx( eye_pos.xyz );
		vec3 q1 = dFdy( eye_pos.xyz );
		vec2 st0 = dFdx( uv.st );
		vec2 st1 = dFdy( uv.st );
		vec3 N = surf_norm;
		vec3 q1perp = cross( q1, N );
		vec3 q0perp = cross( N, q0 );
		vec3 T = q1perp * st0.x + q0perp * st1.x;
		vec3 B = q1perp * st0.y + q0perp * st1.y;
		float det = max( dot( T, T ), dot( B, B ) );
		float scale = ( det == 0.0 ) ? 0.0 : inversesqrt( det );
		return mat3( T * scale, B * scale, N );
	}
#endif`,Yp=`#ifdef USE_CLEARCOAT
	vec3 clearcoatNormal = nonPerturbedNormal;
#endif`,Kp=`#ifdef USE_CLEARCOAT_NORMALMAP
	vec3 clearcoatMapN = texture2D( clearcoatNormalMap, vClearcoatNormalMapUv ).xyz * 2.0 - 1.0;
	clearcoatMapN.xy *= clearcoatNormalScale;
	clearcoatNormal = normalize( tbn2 * clearcoatMapN );
#endif`,$p=`#ifdef USE_CLEARCOATMAP
	uniform sampler2D clearcoatMap;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform sampler2D clearcoatNormalMap;
	uniform vec2 clearcoatNormalScale;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform sampler2D clearcoatRoughnessMap;
#endif`,jp=`#ifdef USE_IRIDESCENCEMAP
	uniform sampler2D iridescenceMap;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	uniform sampler2D iridescenceThicknessMap;
#endif`,Zp=`#ifdef OPAQUE
diffuseColor.a = 1.0;
#endif
#ifdef USE_TRANSMISSION
diffuseColor.a *= material.transmissionAlpha;
#endif
gl_FragColor = vec4( outgoingLight, diffuseColor.a );`,Jp=`vec3 packNormalToRGB( const in vec3 normal ) {
	return normalize( normal ) * 0.5 + 0.5;
}
vec3 unpackRGBToNormal( const in vec3 rgb ) {
	return 2.0 * rgb.xyz - 1.0;
}
const float PackUpscale = 256. / 255.;const float UnpackDownscale = 255. / 256.;const float ShiftRight8 = 1. / 256.;
const float Inv255 = 1. / 255.;
const vec4 PackFactors = vec4( 1.0, 256.0, 256.0 * 256.0, 256.0 * 256.0 * 256.0 );
const vec2 UnpackFactors2 = vec2( UnpackDownscale, 1.0 / PackFactors.g );
const vec3 UnpackFactors3 = vec3( UnpackDownscale / PackFactors.rg, 1.0 / PackFactors.b );
const vec4 UnpackFactors4 = vec4( UnpackDownscale / PackFactors.rgb, 1.0 / PackFactors.a );
vec4 packDepthToRGBA( const in float v ) {
	if( v <= 0.0 )
		return vec4( 0., 0., 0., 0. );
	if( v >= 1.0 )
		return vec4( 1., 1., 1., 1. );
	float vuf;
	float af = modf( v * PackFactors.a, vuf );
	float bf = modf( vuf * ShiftRight8, vuf );
	float gf = modf( vuf * ShiftRight8, vuf );
	return vec4( vuf * Inv255, gf * PackUpscale, bf * PackUpscale, af );
}
vec3 packDepthToRGB( const in float v ) {
	if( v <= 0.0 )
		return vec3( 0., 0., 0. );
	if( v >= 1.0 )
		return vec3( 1., 1., 1. );
	float vuf;
	float bf = modf( v * PackFactors.b, vuf );
	float gf = modf( vuf * ShiftRight8, vuf );
	return vec3( vuf * Inv255, gf * PackUpscale, bf );
}
vec2 packDepthToRG( const in float v ) {
	if( v <= 0.0 )
		return vec2( 0., 0. );
	if( v >= 1.0 )
		return vec2( 1., 1. );
	float vuf;
	float gf = modf( v * 256., vuf );
	return vec2( vuf * Inv255, gf );
}
float unpackRGBAToDepth( const in vec4 v ) {
	return dot( v, UnpackFactors4 );
}
float unpackRGBToDepth( const in vec3 v ) {
	return dot( v, UnpackFactors3 );
}
float unpackRGToDepth( const in vec2 v ) {
	return v.r * UnpackFactors2.r + v.g * UnpackFactors2.g;
}
vec4 pack2HalfToRGBA( const in vec2 v ) {
	vec4 r = vec4( v.x, fract( v.x * 255.0 ), v.y, fract( v.y * 255.0 ) );
	return vec4( r.x - r.y / 255.0, r.y, r.z - r.w / 255.0, r.w );
}
vec2 unpackRGBATo2Half( const in vec4 v ) {
	return vec2( v.x + ( v.y / 255.0 ), v.z + ( v.w / 255.0 ) );
}
float viewZToOrthographicDepth( const in float viewZ, const in float near, const in float far ) {
	return ( viewZ + near ) / ( near - far );
}
float orthographicDepthToViewZ( const in float depth, const in float near, const in float far ) {
	return depth * ( near - far ) - near;
}
float viewZToPerspectiveDepth( const in float viewZ, const in float near, const in float far ) {
	return ( ( near + viewZ ) * far ) / ( ( far - near ) * viewZ );
}
float perspectiveDepthToViewZ( const in float depth, const in float near, const in float far ) {
	return ( near * far ) / ( ( far - near ) * depth - far );
}`,Qp=`#ifdef PREMULTIPLIED_ALPHA
	gl_FragColor.rgb *= gl_FragColor.a;
#endif`,tm=`vec4 mvPosition = vec4( transformed, 1.0 );
#ifdef USE_BATCHING
	mvPosition = batchingMatrix * mvPosition;
#endif
#ifdef USE_INSTANCING
	mvPosition = instanceMatrix * mvPosition;
#endif
mvPosition = modelViewMatrix * mvPosition;
gl_Position = projectionMatrix * mvPosition;`,em=`#ifdef DITHERING
	gl_FragColor.rgb = dithering( gl_FragColor.rgb );
#endif`,nm=`#ifdef DITHERING
	vec3 dithering( vec3 color ) {
		float grid_position = rand( gl_FragCoord.xy );
		vec3 dither_shift_RGB = vec3( 0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0 );
		dither_shift_RGB = mix( 2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position );
		return color + dither_shift_RGB;
	}
#endif`,im=`float roughnessFactor = roughness;
#ifdef USE_ROUGHNESSMAP
	vec4 texelRoughness = texture2D( roughnessMap, vRoughnessMapUv );
	roughnessFactor *= texelRoughness.g;
#endif`,sm=`#ifdef USE_ROUGHNESSMAP
	uniform sampler2D roughnessMap;
#endif`,rm=`#if NUM_SPOT_LIGHT_COORDS > 0
	varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];
#endif
#if NUM_SPOT_LIGHT_MAPS > 0
	uniform sampler2D spotLightMap[ NUM_SPOT_LIGHT_MAPS ];
#endif
#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
		uniform sampler2D directionalShadowMap[ NUM_DIR_LIGHT_SHADOWS ];
		varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];
		struct DirectionalLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
		uniform sampler2D spotShadowMap[ NUM_SPOT_LIGHT_SHADOWS ];
		struct SpotLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		uniform sampler2D pointShadowMap[ NUM_POINT_LIGHT_SHADOWS ];
		varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];
		struct PointLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
			float shadowCameraNear;
			float shadowCameraFar;
		};
		uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];
	#endif
	float texture2DCompare( sampler2D depths, vec2 uv, float compare ) {
		return step( compare, unpackRGBAToDepth( texture2D( depths, uv ) ) );
	}
	vec2 texture2DDistribution( sampler2D shadow, vec2 uv ) {
		return unpackRGBATo2Half( texture2D( shadow, uv ) );
	}
	float VSMShadow (sampler2D shadow, vec2 uv, float compare ){
		float occlusion = 1.0;
		vec2 distribution = texture2DDistribution( shadow, uv );
		float hard_shadow = step( compare , distribution.x );
		if (hard_shadow != 1.0 ) {
			float distance = compare - distribution.x ;
			float variance = max( 0.00000, distribution.y * distribution.y );
			float softness_probability = variance / (variance + distance * distance );			softness_probability = clamp( ( softness_probability - 0.3 ) / ( 0.95 - 0.3 ), 0.0, 1.0 );			occlusion = clamp( max( hard_shadow, softness_probability ), 0.0, 1.0 );
		}
		return occlusion;
	}
	float getShadow( sampler2D shadowMap, vec2 shadowMapSize, float shadowIntensity, float shadowBias, float shadowRadius, vec4 shadowCoord ) {
		float shadow = 1.0;
		shadowCoord.xyz /= shadowCoord.w;
		shadowCoord.z += shadowBias;
		bool inFrustum = shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 && shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0;
		bool frustumTest = inFrustum && shadowCoord.z <= 1.0;
		if ( frustumTest ) {
		#if defined( SHADOWMAP_TYPE_PCF )
			vec2 texelSize = vec2( 1.0 ) / shadowMapSize;
			float dx0 = - texelSize.x * shadowRadius;
			float dy0 = - texelSize.y * shadowRadius;
			float dx1 = + texelSize.x * shadowRadius;
			float dy1 = + texelSize.y * shadowRadius;
			float dx2 = dx0 / 2.0;
			float dy2 = dy0 / 2.0;
			float dx3 = dx1 / 2.0;
			float dy3 = dy1 / 2.0;
			shadow = (
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy, shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, dy1 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy1 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, dy1 ), shadowCoord.z )
			) * ( 1.0 / 17.0 );
		#elif defined( SHADOWMAP_TYPE_PCF_SOFT )
			vec2 texelSize = vec2( 1.0 ) / shadowMapSize;
			float dx = texelSize.x;
			float dy = texelSize.y;
			vec2 uv = shadowCoord.xy;
			vec2 f = fract( uv * shadowMapSize + 0.5 );
			uv -= f * texelSize;
			shadow = (
				texture2DCompare( shadowMap, uv, shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + vec2( dx, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + vec2( 0.0, dy ), shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + texelSize, shadowCoord.z ) +
				mix( texture2DCompare( shadowMap, uv + vec2( -dx, 0.0 ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, 0.0 ), shadowCoord.z ),
					 f.x ) +
				mix( texture2DCompare( shadowMap, uv + vec2( -dx, dy ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, dy ), shadowCoord.z ),
					 f.x ) +
				mix( texture2DCompare( shadowMap, uv + vec2( 0.0, -dy ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( 0.0, 2.0 * dy ), shadowCoord.z ),
					 f.y ) +
				mix( texture2DCompare( shadowMap, uv + vec2( dx, -dy ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( dx, 2.0 * dy ), shadowCoord.z ),
					 f.y ) +
				mix( mix( texture2DCompare( shadowMap, uv + vec2( -dx, -dy ), shadowCoord.z ),
						  texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, -dy ), shadowCoord.z ),
						  f.x ),
					 mix( texture2DCompare( shadowMap, uv + vec2( -dx, 2.0 * dy ), shadowCoord.z ),
						  texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, 2.0 * dy ), shadowCoord.z ),
						  f.x ),
					 f.y )
			) * ( 1.0 / 9.0 );
		#elif defined( SHADOWMAP_TYPE_VSM )
			shadow = VSMShadow( shadowMap, shadowCoord.xy, shadowCoord.z );
		#else
			shadow = texture2DCompare( shadowMap, shadowCoord.xy, shadowCoord.z );
		#endif
		}
		return mix( 1.0, shadow, shadowIntensity );
	}
	vec2 cubeToUV( vec3 v, float texelSizeY ) {
		vec3 absV = abs( v );
		float scaleToCube = 1.0 / max( absV.x, max( absV.y, absV.z ) );
		absV *= scaleToCube;
		v *= scaleToCube * ( 1.0 - 2.0 * texelSizeY );
		vec2 planar = v.xy;
		float almostATexel = 1.5 * texelSizeY;
		float almostOne = 1.0 - almostATexel;
		if ( absV.z >= almostOne ) {
			if ( v.z > 0.0 )
				planar.x = 4.0 - v.x;
		} else if ( absV.x >= almostOne ) {
			float signX = sign( v.x );
			planar.x = v.z * signX + 2.0 * signX;
		} else if ( absV.y >= almostOne ) {
			float signY = sign( v.y );
			planar.x = v.x + 2.0 * signY + 2.0;
			planar.y = v.z * signY - 2.0;
		}
		return vec2( 0.125, 0.25 ) * planar + vec2( 0.375, 0.75 );
	}
	float getPointShadow( sampler2D shadowMap, vec2 shadowMapSize, float shadowIntensity, float shadowBias, float shadowRadius, vec4 shadowCoord, float shadowCameraNear, float shadowCameraFar ) {
		float shadow = 1.0;
		vec3 lightToPosition = shadowCoord.xyz;
		
		float lightToPositionLength = length( lightToPosition );
		if ( lightToPositionLength - shadowCameraFar <= 0.0 && lightToPositionLength - shadowCameraNear >= 0.0 ) {
			float dp = ( lightToPositionLength - shadowCameraNear ) / ( shadowCameraFar - shadowCameraNear );			dp += shadowBias;
			vec3 bd3D = normalize( lightToPosition );
			vec2 texelSize = vec2( 1.0 ) / ( shadowMapSize * vec2( 4.0, 2.0 ) );
			#if defined( SHADOWMAP_TYPE_PCF ) || defined( SHADOWMAP_TYPE_PCF_SOFT ) || defined( SHADOWMAP_TYPE_VSM )
				vec2 offset = vec2( - 1, 1 ) * shadowRadius * texelSize.y;
				shadow = (
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xyy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yyy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xyx, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yyx, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xxy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yxy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xxx, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yxx, texelSize.y ), dp )
				) * ( 1.0 / 9.0 );
			#else
				shadow = texture2DCompare( shadowMap, cubeToUV( bd3D, texelSize.y ), dp );
			#endif
		}
		return mix( 1.0, shadow, shadowIntensity );
	}
#endif`,am=`#if NUM_SPOT_LIGHT_COORDS > 0
	uniform mat4 spotLightMatrix[ NUM_SPOT_LIGHT_COORDS ];
	varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];
#endif
#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
		uniform mat4 directionalShadowMatrix[ NUM_DIR_LIGHT_SHADOWS ];
		varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];
		struct DirectionalLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
		struct SpotLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		uniform mat4 pointShadowMatrix[ NUM_POINT_LIGHT_SHADOWS ];
		varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];
		struct PointLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
			float shadowCameraNear;
			float shadowCameraFar;
		};
		uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];
	#endif
#endif`,om=`#if ( defined( USE_SHADOWMAP ) && ( NUM_DIR_LIGHT_SHADOWS > 0 || NUM_POINT_LIGHT_SHADOWS > 0 ) ) || ( NUM_SPOT_LIGHT_COORDS > 0 )
	vec3 shadowWorldNormal = inverseTransformDirection( transformedNormal, viewMatrix );
	vec4 shadowWorldPosition;
#endif
#if defined( USE_SHADOWMAP )
	#if NUM_DIR_LIGHT_SHADOWS > 0
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {
			shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * directionalLightShadows[ i ].shadowNormalBias, 0 );
			vDirectionalShadowCoord[ i ] = directionalShadowMatrix[ i ] * shadowWorldPosition;
		}
		#pragma unroll_loop_end
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {
			shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * pointLightShadows[ i ].shadowNormalBias, 0 );
			vPointShadowCoord[ i ] = pointShadowMatrix[ i ] * shadowWorldPosition;
		}
		#pragma unroll_loop_end
	#endif
#endif
#if NUM_SPOT_LIGHT_COORDS > 0
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHT_COORDS; i ++ ) {
		shadowWorldPosition = worldPosition;
		#if ( defined( USE_SHADOWMAP ) && UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
			shadowWorldPosition.xyz += shadowWorldNormal * spotLightShadows[ i ].shadowNormalBias;
		#endif
		vSpotLightCoord[ i ] = spotLightMatrix[ i ] * shadowWorldPosition;
	}
	#pragma unroll_loop_end
#endif`,lm=`float getShadowMask() {
	float shadow = 1.0;
	#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {
		directionalLight = directionalLightShadows[ i ];
		shadow *= receiveShadow ? getShadow( directionalShadowMap[ i ], directionalLight.shadowMapSize, directionalLight.shadowIntensity, directionalLight.shadowBias, directionalLight.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHT_SHADOWS; i ++ ) {
		spotLight = spotLightShadows[ i ];
		shadow *= receiveShadow ? getShadow( spotShadowMap[ i ], spotLight.shadowMapSize, spotLight.shadowIntensity, spotLight.shadowBias, spotLight.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
	PointLightShadow pointLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {
		pointLight = pointLightShadows[ i ];
		shadow *= receiveShadow ? getPointShadow( pointShadowMap[ i ], pointLight.shadowMapSize, pointLight.shadowIntensity, pointLight.shadowBias, pointLight.shadowRadius, vPointShadowCoord[ i ], pointLight.shadowCameraNear, pointLight.shadowCameraFar ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#endif
	return shadow;
}`,cm=`#ifdef USE_SKINNING
	mat4 boneMatX = getBoneMatrix( skinIndex.x );
	mat4 boneMatY = getBoneMatrix( skinIndex.y );
	mat4 boneMatZ = getBoneMatrix( skinIndex.z );
	mat4 boneMatW = getBoneMatrix( skinIndex.w );
#endif`,hm=`#ifdef USE_SKINNING
	uniform mat4 bindMatrix;
	uniform mat4 bindMatrixInverse;
	uniform highp sampler2D boneTexture;
	mat4 getBoneMatrix( const in float i ) {
		int size = textureSize( boneTexture, 0 ).x;
		int j = int( i ) * 4;
		int x = j % size;
		int y = j / size;
		vec4 v1 = texelFetch( boneTexture, ivec2( x, y ), 0 );
		vec4 v2 = texelFetch( boneTexture, ivec2( x + 1, y ), 0 );
		vec4 v3 = texelFetch( boneTexture, ivec2( x + 2, y ), 0 );
		vec4 v4 = texelFetch( boneTexture, ivec2( x + 3, y ), 0 );
		return mat4( v1, v2, v3, v4 );
	}
#endif`,um=`#ifdef USE_SKINNING
	vec4 skinVertex = bindMatrix * vec4( transformed, 1.0 );
	vec4 skinned = vec4( 0.0 );
	skinned += boneMatX * skinVertex * skinWeight.x;
	skinned += boneMatY * skinVertex * skinWeight.y;
	skinned += boneMatZ * skinVertex * skinWeight.z;
	skinned += boneMatW * skinVertex * skinWeight.w;
	transformed = ( bindMatrixInverse * skinned ).xyz;
#endif`,dm=`#ifdef USE_SKINNING
	mat4 skinMatrix = mat4( 0.0 );
	skinMatrix += skinWeight.x * boneMatX;
	skinMatrix += skinWeight.y * boneMatY;
	skinMatrix += skinWeight.z * boneMatZ;
	skinMatrix += skinWeight.w * boneMatW;
	skinMatrix = bindMatrixInverse * skinMatrix * bindMatrix;
	objectNormal = vec4( skinMatrix * vec4( objectNormal, 0.0 ) ).xyz;
	#ifdef USE_TANGENT
		objectTangent = vec4( skinMatrix * vec4( objectTangent, 0.0 ) ).xyz;
	#endif
#endif`,fm=`float specularStrength;
#ifdef USE_SPECULARMAP
	vec4 texelSpecular = texture2D( specularMap, vSpecularMapUv );
	specularStrength = texelSpecular.r;
#else
	specularStrength = 1.0;
#endif`,pm=`#ifdef USE_SPECULARMAP
	uniform sampler2D specularMap;
#endif`,mm=`#if defined( TONE_MAPPING )
	gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );
#endif`,gm=`#ifndef saturate
#define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
uniform float toneMappingExposure;
vec3 LinearToneMapping( vec3 color ) {
	return saturate( toneMappingExposure * color );
}
vec3 ReinhardToneMapping( vec3 color ) {
	color *= toneMappingExposure;
	return saturate( color / ( vec3( 1.0 ) + color ) );
}
vec3 CineonToneMapping( vec3 color ) {
	color *= toneMappingExposure;
	color = max( vec3( 0.0 ), color - 0.004 );
	return pow( ( color * ( 6.2 * color + 0.5 ) ) / ( color * ( 6.2 * color + 1.7 ) + 0.06 ), vec3( 2.2 ) );
}
vec3 RRTAndODTFit( vec3 v ) {
	vec3 a = v * ( v + 0.0245786 ) - 0.000090537;
	vec3 b = v * ( 0.983729 * v + 0.4329510 ) + 0.238081;
	return a / b;
}
vec3 ACESFilmicToneMapping( vec3 color ) {
	const mat3 ACESInputMat = mat3(
		vec3( 0.59719, 0.07600, 0.02840 ),		vec3( 0.35458, 0.90834, 0.13383 ),
		vec3( 0.04823, 0.01566, 0.83777 )
	);
	const mat3 ACESOutputMat = mat3(
		vec3(  1.60475, -0.10208, -0.00327 ),		vec3( -0.53108,  1.10813, -0.07276 ),
		vec3( -0.07367, -0.00605,  1.07602 )
	);
	color *= toneMappingExposure / 0.6;
	color = ACESInputMat * color;
	color = RRTAndODTFit( color );
	color = ACESOutputMat * color;
	return saturate( color );
}
const mat3 LINEAR_REC2020_TO_LINEAR_SRGB = mat3(
	vec3( 1.6605, - 0.1246, - 0.0182 ),
	vec3( - 0.5876, 1.1329, - 0.1006 ),
	vec3( - 0.0728, - 0.0083, 1.1187 )
);
const mat3 LINEAR_SRGB_TO_LINEAR_REC2020 = mat3(
	vec3( 0.6274, 0.0691, 0.0164 ),
	vec3( 0.3293, 0.9195, 0.0880 ),
	vec3( 0.0433, 0.0113, 0.8956 )
);
vec3 agxDefaultContrastApprox( vec3 x ) {
	vec3 x2 = x * x;
	vec3 x4 = x2 * x2;
	return + 15.5 * x4 * x2
		- 40.14 * x4 * x
		+ 31.96 * x4
		- 6.868 * x2 * x
		+ 0.4298 * x2
		+ 0.1191 * x
		- 0.00232;
}
vec3 AgXToneMapping( vec3 color ) {
	const mat3 AgXInsetMatrix = mat3(
		vec3( 0.856627153315983, 0.137318972929847, 0.11189821299995 ),
		vec3( 0.0951212405381588, 0.761241990602591, 0.0767994186031903 ),
		vec3( 0.0482516061458583, 0.101439036467562, 0.811302368396859 )
	);
	const mat3 AgXOutsetMatrix = mat3(
		vec3( 1.1271005818144368, - 0.1413297634984383, - 0.14132976349843826 ),
		vec3( - 0.11060664309660323, 1.157823702216272, - 0.11060664309660294 ),
		vec3( - 0.016493938717834573, - 0.016493938717834257, 1.2519364065950405 )
	);
	const float AgxMinEv = - 12.47393;	const float AgxMaxEv = 4.026069;
	color *= toneMappingExposure;
	color = LINEAR_SRGB_TO_LINEAR_REC2020 * color;
	color = AgXInsetMatrix * color;
	color = max( color, 1e-10 );	color = log2( color );
	color = ( color - AgxMinEv ) / ( AgxMaxEv - AgxMinEv );
	color = clamp( color, 0.0, 1.0 );
	color = agxDefaultContrastApprox( color );
	color = AgXOutsetMatrix * color;
	color = pow( max( vec3( 0.0 ), color ), vec3( 2.2 ) );
	color = LINEAR_REC2020_TO_LINEAR_SRGB * color;
	color = clamp( color, 0.0, 1.0 );
	return color;
}
vec3 NeutralToneMapping( vec3 color ) {
	const float StartCompression = 0.8 - 0.04;
	const float Desaturation = 0.15;
	color *= toneMappingExposure;
	float x = min( color.r, min( color.g, color.b ) );
	float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
	color -= offset;
	float peak = max( color.r, max( color.g, color.b ) );
	if ( peak < StartCompression ) return color;
	float d = 1. - StartCompression;
	float newPeak = 1. - d * d / ( peak + d - StartCompression );
	color *= newPeak / peak;
	float g = 1. - 1. / ( Desaturation * ( peak - newPeak ) + 1. );
	return mix( color, vec3( newPeak ), g );
}
vec3 CustomToneMapping( vec3 color ) { return color; }`,vm=`#ifdef USE_TRANSMISSION
	material.transmission = transmission;
	material.transmissionAlpha = 1.0;
	material.thickness = thickness;
	material.attenuationDistance = attenuationDistance;
	material.attenuationColor = attenuationColor;
	#ifdef USE_TRANSMISSIONMAP
		material.transmission *= texture2D( transmissionMap, vTransmissionMapUv ).r;
	#endif
	#ifdef USE_THICKNESSMAP
		material.thickness *= texture2D( thicknessMap, vThicknessMapUv ).g;
	#endif
	vec3 pos = vWorldPosition;
	vec3 v = normalize( cameraPosition - pos );
	vec3 n = inverseTransformDirection( normal, viewMatrix );
	vec4 transmitted = getIBLVolumeRefraction(
		n, v, material.roughness, material.diffuseColor, material.specularColor, material.specularF90,
		pos, modelMatrix, viewMatrix, projectionMatrix, material.dispersion, material.ior, material.thickness,
		material.attenuationColor, material.attenuationDistance );
	material.transmissionAlpha = mix( material.transmissionAlpha, transmitted.a, material.transmission );
	totalDiffuse = mix( totalDiffuse, transmitted.rgb, material.transmission );
#endif`,_m=`#ifdef USE_TRANSMISSION
	uniform float transmission;
	uniform float thickness;
	uniform float attenuationDistance;
	uniform vec3 attenuationColor;
	#ifdef USE_TRANSMISSIONMAP
		uniform sampler2D transmissionMap;
	#endif
	#ifdef USE_THICKNESSMAP
		uniform sampler2D thicknessMap;
	#endif
	uniform vec2 transmissionSamplerSize;
	uniform sampler2D transmissionSamplerMap;
	uniform mat4 modelMatrix;
	uniform mat4 projectionMatrix;
	varying vec3 vWorldPosition;
	float w0( float a ) {
		return ( 1.0 / 6.0 ) * ( a * ( a * ( - a + 3.0 ) - 3.0 ) + 1.0 );
	}
	float w1( float a ) {
		return ( 1.0 / 6.0 ) * ( a *  a * ( 3.0 * a - 6.0 ) + 4.0 );
	}
	float w2( float a ){
		return ( 1.0 / 6.0 ) * ( a * ( a * ( - 3.0 * a + 3.0 ) + 3.0 ) + 1.0 );
	}
	float w3( float a ) {
		return ( 1.0 / 6.0 ) * ( a * a * a );
	}
	float g0( float a ) {
		return w0( a ) + w1( a );
	}
	float g1( float a ) {
		return w2( a ) + w3( a );
	}
	float h0( float a ) {
		return - 1.0 + w1( a ) / ( w0( a ) + w1( a ) );
	}
	float h1( float a ) {
		return 1.0 + w3( a ) / ( w2( a ) + w3( a ) );
	}
	vec4 bicubic( sampler2D tex, vec2 uv, vec4 texelSize, float lod ) {
		uv = uv * texelSize.zw + 0.5;
		vec2 iuv = floor( uv );
		vec2 fuv = fract( uv );
		float g0x = g0( fuv.x );
		float g1x = g1( fuv.x );
		float h0x = h0( fuv.x );
		float h1x = h1( fuv.x );
		float h0y = h0( fuv.y );
		float h1y = h1( fuv.y );
		vec2 p0 = ( vec2( iuv.x + h0x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;
		vec2 p1 = ( vec2( iuv.x + h1x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;
		vec2 p2 = ( vec2( iuv.x + h0x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;
		vec2 p3 = ( vec2( iuv.x + h1x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;
		return g0( fuv.y ) * ( g0x * textureLod( tex, p0, lod ) + g1x * textureLod( tex, p1, lod ) ) +
			g1( fuv.y ) * ( g0x * textureLod( tex, p2, lod ) + g1x * textureLod( tex, p3, lod ) );
	}
	vec4 textureBicubic( sampler2D sampler, vec2 uv, float lod ) {
		vec2 fLodSize = vec2( textureSize( sampler, int( lod ) ) );
		vec2 cLodSize = vec2( textureSize( sampler, int( lod + 1.0 ) ) );
		vec2 fLodSizeInv = 1.0 / fLodSize;
		vec2 cLodSizeInv = 1.0 / cLodSize;
		vec4 fSample = bicubic( sampler, uv, vec4( fLodSizeInv, fLodSize ), floor( lod ) );
		vec4 cSample = bicubic( sampler, uv, vec4( cLodSizeInv, cLodSize ), ceil( lod ) );
		return mix( fSample, cSample, fract( lod ) );
	}
	vec3 getVolumeTransmissionRay( const in vec3 n, const in vec3 v, const in float thickness, const in float ior, const in mat4 modelMatrix ) {
		vec3 refractionVector = refract( - v, normalize( n ), 1.0 / ior );
		vec3 modelScale;
		modelScale.x = length( vec3( modelMatrix[ 0 ].xyz ) );
		modelScale.y = length( vec3( modelMatrix[ 1 ].xyz ) );
		modelScale.z = length( vec3( modelMatrix[ 2 ].xyz ) );
		return normalize( refractionVector ) * thickness * modelScale;
	}
	float applyIorToRoughness( const in float roughness, const in float ior ) {
		return roughness * clamp( ior * 2.0 - 2.0, 0.0, 1.0 );
	}
	vec4 getTransmissionSample( const in vec2 fragCoord, const in float roughness, const in float ior ) {
		float lod = log2( transmissionSamplerSize.x ) * applyIorToRoughness( roughness, ior );
		return textureBicubic( transmissionSamplerMap, fragCoord.xy, lod );
	}
	vec3 volumeAttenuation( const in float transmissionDistance, const in vec3 attenuationColor, const in float attenuationDistance ) {
		if ( isinf( attenuationDistance ) ) {
			return vec3( 1.0 );
		} else {
			vec3 attenuationCoefficient = -log( attenuationColor ) / attenuationDistance;
			vec3 transmittance = exp( - attenuationCoefficient * transmissionDistance );			return transmittance;
		}
	}
	vec4 getIBLVolumeRefraction( const in vec3 n, const in vec3 v, const in float roughness, const in vec3 diffuseColor,
		const in vec3 specularColor, const in float specularF90, const in vec3 position, const in mat4 modelMatrix,
		const in mat4 viewMatrix, const in mat4 projMatrix, const in float dispersion, const in float ior, const in float thickness,
		const in vec3 attenuationColor, const in float attenuationDistance ) {
		vec4 transmittedLight;
		vec3 transmittance;
		#ifdef USE_DISPERSION
			float halfSpread = ( ior - 1.0 ) * 0.025 * dispersion;
			vec3 iors = vec3( ior - halfSpread, ior, ior + halfSpread );
			for ( int i = 0; i < 3; i ++ ) {
				vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, iors[ i ], modelMatrix );
				vec3 refractedRayExit = position + transmissionRay;
		
				vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );
				vec2 refractionCoords = ndcPos.xy / ndcPos.w;
				refractionCoords += 1.0;
				refractionCoords /= 2.0;
		
				vec4 transmissionSample = getTransmissionSample( refractionCoords, roughness, iors[ i ] );
				transmittedLight[ i ] = transmissionSample[ i ];
				transmittedLight.a += transmissionSample.a;
				transmittance[ i ] = diffuseColor[ i ] * volumeAttenuation( length( transmissionRay ), attenuationColor, attenuationDistance )[ i ];
			}
			transmittedLight.a /= 3.0;
		
		#else
		
			vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, ior, modelMatrix );
			vec3 refractedRayExit = position + transmissionRay;
			vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );
			vec2 refractionCoords = ndcPos.xy / ndcPos.w;
			refractionCoords += 1.0;
			refractionCoords /= 2.0;
			transmittedLight = getTransmissionSample( refractionCoords, roughness, ior );
			transmittance = diffuseColor * volumeAttenuation( length( transmissionRay ), attenuationColor, attenuationDistance );
		
		#endif
		vec3 attenuatedColor = transmittance * transmittedLight.rgb;
		vec3 F = EnvironmentBRDF( n, v, specularColor, specularF90, roughness );
		float transmittanceFactor = ( transmittance.r + transmittance.g + transmittance.b ) / 3.0;
		return vec4( ( 1.0 - F ) * attenuatedColor, 1.0 - ( 1.0 - transmittedLight.a ) * transmittanceFactor );
	}
#endif`,xm=`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	varying vec2 vUv;
#endif
#ifdef USE_MAP
	varying vec2 vMapUv;
#endif
#ifdef USE_ALPHAMAP
	varying vec2 vAlphaMapUv;
#endif
#ifdef USE_LIGHTMAP
	varying vec2 vLightMapUv;
#endif
#ifdef USE_AOMAP
	varying vec2 vAoMapUv;
#endif
#ifdef USE_BUMPMAP
	varying vec2 vBumpMapUv;
#endif
#ifdef USE_NORMALMAP
	varying vec2 vNormalMapUv;
#endif
#ifdef USE_EMISSIVEMAP
	varying vec2 vEmissiveMapUv;
#endif
#ifdef USE_METALNESSMAP
	varying vec2 vMetalnessMapUv;
#endif
#ifdef USE_ROUGHNESSMAP
	varying vec2 vRoughnessMapUv;
#endif
#ifdef USE_ANISOTROPYMAP
	varying vec2 vAnisotropyMapUv;
#endif
#ifdef USE_CLEARCOATMAP
	varying vec2 vClearcoatMapUv;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	varying vec2 vClearcoatNormalMapUv;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	varying vec2 vClearcoatRoughnessMapUv;
#endif
#ifdef USE_IRIDESCENCEMAP
	varying vec2 vIridescenceMapUv;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	varying vec2 vIridescenceThicknessMapUv;
#endif
#ifdef USE_SHEEN_COLORMAP
	varying vec2 vSheenColorMapUv;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	varying vec2 vSheenRoughnessMapUv;
#endif
#ifdef USE_SPECULARMAP
	varying vec2 vSpecularMapUv;
#endif
#ifdef USE_SPECULAR_COLORMAP
	varying vec2 vSpecularColorMapUv;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	varying vec2 vSpecularIntensityMapUv;
#endif
#ifdef USE_TRANSMISSIONMAP
	uniform mat3 transmissionMapTransform;
	varying vec2 vTransmissionMapUv;
#endif
#ifdef USE_THICKNESSMAP
	uniform mat3 thicknessMapTransform;
	varying vec2 vThicknessMapUv;
#endif`,ym=`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	varying vec2 vUv;
#endif
#ifdef USE_MAP
	uniform mat3 mapTransform;
	varying vec2 vMapUv;
#endif
#ifdef USE_ALPHAMAP
	uniform mat3 alphaMapTransform;
	varying vec2 vAlphaMapUv;
#endif
#ifdef USE_LIGHTMAP
	uniform mat3 lightMapTransform;
	varying vec2 vLightMapUv;
#endif
#ifdef USE_AOMAP
	uniform mat3 aoMapTransform;
	varying vec2 vAoMapUv;
#endif
#ifdef USE_BUMPMAP
	uniform mat3 bumpMapTransform;
	varying vec2 vBumpMapUv;
#endif
#ifdef USE_NORMALMAP
	uniform mat3 normalMapTransform;
	varying vec2 vNormalMapUv;
#endif
#ifdef USE_DISPLACEMENTMAP
	uniform mat3 displacementMapTransform;
	varying vec2 vDisplacementMapUv;
#endif
#ifdef USE_EMISSIVEMAP
	uniform mat3 emissiveMapTransform;
	varying vec2 vEmissiveMapUv;
#endif
#ifdef USE_METALNESSMAP
	uniform mat3 metalnessMapTransform;
	varying vec2 vMetalnessMapUv;
#endif
#ifdef USE_ROUGHNESSMAP
	uniform mat3 roughnessMapTransform;
	varying vec2 vRoughnessMapUv;
#endif
#ifdef USE_ANISOTROPYMAP
	uniform mat3 anisotropyMapTransform;
	varying vec2 vAnisotropyMapUv;
#endif
#ifdef USE_CLEARCOATMAP
	uniform mat3 clearcoatMapTransform;
	varying vec2 vClearcoatMapUv;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform mat3 clearcoatNormalMapTransform;
	varying vec2 vClearcoatNormalMapUv;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform mat3 clearcoatRoughnessMapTransform;
	varying vec2 vClearcoatRoughnessMapUv;
#endif
#ifdef USE_SHEEN_COLORMAP
	uniform mat3 sheenColorMapTransform;
	varying vec2 vSheenColorMapUv;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	uniform mat3 sheenRoughnessMapTransform;
	varying vec2 vSheenRoughnessMapUv;
#endif
#ifdef USE_IRIDESCENCEMAP
	uniform mat3 iridescenceMapTransform;
	varying vec2 vIridescenceMapUv;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	uniform mat3 iridescenceThicknessMapTransform;
	varying vec2 vIridescenceThicknessMapUv;
#endif
#ifdef USE_SPECULARMAP
	uniform mat3 specularMapTransform;
	varying vec2 vSpecularMapUv;
#endif
#ifdef USE_SPECULAR_COLORMAP
	uniform mat3 specularColorMapTransform;
	varying vec2 vSpecularColorMapUv;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	uniform mat3 specularIntensityMapTransform;
	varying vec2 vSpecularIntensityMapUv;
#endif
#ifdef USE_TRANSMISSIONMAP
	uniform mat3 transmissionMapTransform;
	varying vec2 vTransmissionMapUv;
#endif
#ifdef USE_THICKNESSMAP
	uniform mat3 thicknessMapTransform;
	varying vec2 vThicknessMapUv;
#endif`,Mm=`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	vUv = vec3( uv, 1 ).xy;
#endif
#ifdef USE_MAP
	vMapUv = ( mapTransform * vec3( MAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ALPHAMAP
	vAlphaMapUv = ( alphaMapTransform * vec3( ALPHAMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_LIGHTMAP
	vLightMapUv = ( lightMapTransform * vec3( LIGHTMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_AOMAP
	vAoMapUv = ( aoMapTransform * vec3( AOMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_BUMPMAP
	vBumpMapUv = ( bumpMapTransform * vec3( BUMPMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_NORMALMAP
	vNormalMapUv = ( normalMapTransform * vec3( NORMALMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_DISPLACEMENTMAP
	vDisplacementMapUv = ( displacementMapTransform * vec3( DISPLACEMENTMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_EMISSIVEMAP
	vEmissiveMapUv = ( emissiveMapTransform * vec3( EMISSIVEMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_METALNESSMAP
	vMetalnessMapUv = ( metalnessMapTransform * vec3( METALNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ROUGHNESSMAP
	vRoughnessMapUv = ( roughnessMapTransform * vec3( ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ANISOTROPYMAP
	vAnisotropyMapUv = ( anisotropyMapTransform * vec3( ANISOTROPYMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOATMAP
	vClearcoatMapUv = ( clearcoatMapTransform * vec3( CLEARCOATMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	vClearcoatNormalMapUv = ( clearcoatNormalMapTransform * vec3( CLEARCOAT_NORMALMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	vClearcoatRoughnessMapUv = ( clearcoatRoughnessMapTransform * vec3( CLEARCOAT_ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_IRIDESCENCEMAP
	vIridescenceMapUv = ( iridescenceMapTransform * vec3( IRIDESCENCEMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	vIridescenceThicknessMapUv = ( iridescenceThicknessMapTransform * vec3( IRIDESCENCE_THICKNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SHEEN_COLORMAP
	vSheenColorMapUv = ( sheenColorMapTransform * vec3( SHEEN_COLORMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	vSheenRoughnessMapUv = ( sheenRoughnessMapTransform * vec3( SHEEN_ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULARMAP
	vSpecularMapUv = ( specularMapTransform * vec3( SPECULARMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULAR_COLORMAP
	vSpecularColorMapUv = ( specularColorMapTransform * vec3( SPECULAR_COLORMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	vSpecularIntensityMapUv = ( specularIntensityMapTransform * vec3( SPECULAR_INTENSITYMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_TRANSMISSIONMAP
	vTransmissionMapUv = ( transmissionMapTransform * vec3( TRANSMISSIONMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_THICKNESSMAP
	vThicknessMapUv = ( thicknessMapTransform * vec3( THICKNESSMAP_UV, 1 ) ).xy;
#endif`,bm=`#if defined( USE_ENVMAP ) || defined( DISTANCE ) || defined ( USE_SHADOWMAP ) || defined ( USE_TRANSMISSION ) || NUM_SPOT_LIGHT_COORDS > 0
	vec4 worldPosition = vec4( transformed, 1.0 );
	#ifdef USE_BATCHING
		worldPosition = batchingMatrix * worldPosition;
	#endif
	#ifdef USE_INSTANCING
		worldPosition = instanceMatrix * worldPosition;
	#endif
	worldPosition = modelMatrix * worldPosition;
#endif`;const Sm=`varying vec2 vUv;
uniform mat3 uvTransform;
void main() {
	vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	gl_Position = vec4( position.xy, 1.0, 1.0 );
}`,wm=`uniform sampler2D t2D;
uniform float backgroundIntensity;
varying vec2 vUv;
void main() {
	vec4 texColor = texture2D( t2D, vUv );
	#ifdef DECODE_VIDEO_TEXTURE
		texColor = vec4( mix( pow( texColor.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), texColor.rgb * 0.0773993808, vec3( lessThanEqual( texColor.rgb, vec3( 0.04045 ) ) ) ), texColor.w );
	#endif
	texColor.rgb *= backgroundIntensity;
	gl_FragColor = texColor;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,Tm=`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`,Em=`#ifdef ENVMAP_TYPE_CUBE
	uniform samplerCube envMap;
#elif defined( ENVMAP_TYPE_CUBE_UV )
	uniform sampler2D envMap;
#endif
uniform float flipEnvMap;
uniform float backgroundBlurriness;
uniform float backgroundIntensity;
uniform mat3 backgroundRotation;
varying vec3 vWorldDirection;
#include <cube_uv_reflection_fragment>
void main() {
	#ifdef ENVMAP_TYPE_CUBE
		vec4 texColor = textureCube( envMap, backgroundRotation * vec3( flipEnvMap * vWorldDirection.x, vWorldDirection.yz ) );
	#elif defined( ENVMAP_TYPE_CUBE_UV )
		vec4 texColor = textureCubeUV( envMap, backgroundRotation * vWorldDirection, backgroundBlurriness );
	#else
		vec4 texColor = vec4( 0.0, 0.0, 0.0, 1.0 );
	#endif
	texColor.rgb *= backgroundIntensity;
	gl_FragColor = texColor;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,Am=`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`,Rm=`uniform samplerCube tCube;
uniform float tFlip;
uniform float opacity;
varying vec3 vWorldDirection;
void main() {
	vec4 texColor = textureCube( tCube, vec3( tFlip * vWorldDirection.x, vWorldDirection.yz ) );
	gl_FragColor = texColor;
	gl_FragColor.a *= opacity;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,Cm=`#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
varying vec2 vHighPrecisionZW;
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <skinbase_vertex>
	#include <morphinstance_vertex>
	#ifdef USE_DISPLACEMENTMAP
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vHighPrecisionZW = gl_Position.zw;
}`,Pm=`#if DEPTH_PACKING == 3200
	uniform float opacity;
#endif
#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
varying vec2 vHighPrecisionZW;
void main() {
	vec4 diffuseColor = vec4( 1.0 );
	#include <clipping_planes_fragment>
	#if DEPTH_PACKING == 3200
		diffuseColor.a = opacity;
	#endif
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <logdepthbuf_fragment>
	float fragCoordZ = 0.5 * vHighPrecisionZW[0] / vHighPrecisionZW[1] + 0.5;
	#if DEPTH_PACKING == 3200
		gl_FragColor = vec4( vec3( 1.0 - fragCoordZ ), opacity );
	#elif DEPTH_PACKING == 3201
		gl_FragColor = packDepthToRGBA( fragCoordZ );
	#elif DEPTH_PACKING == 3202
		gl_FragColor = vec4( packDepthToRGB( fragCoordZ ), 1.0 );
	#elif DEPTH_PACKING == 3203
		gl_FragColor = vec4( packDepthToRG( fragCoordZ ), 0.0, 1.0 );
	#endif
}`,Lm=`#define DISTANCE
varying vec3 vWorldPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <skinbase_vertex>
	#include <morphinstance_vertex>
	#ifdef USE_DISPLACEMENTMAP
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <worldpos_vertex>
	#include <clipping_planes_vertex>
	vWorldPosition = worldPosition.xyz;
}`,Im=`#define DISTANCE
uniform vec3 referencePosition;
uniform float nearDistance;
uniform float farDistance;
varying vec3 vWorldPosition;
#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <clipping_planes_pars_fragment>
void main () {
	vec4 diffuseColor = vec4( 1.0 );
	#include <clipping_planes_fragment>
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	float dist = length( vWorldPosition - referencePosition );
	dist = ( dist - nearDistance ) / ( farDistance - nearDistance );
	dist = saturate( dist );
	gl_FragColor = packDepthToRGBA( dist );
}`,Dm=`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
}`,Nm=`uniform sampler2D tEquirect;
varying vec3 vWorldDirection;
#include <common>
void main() {
	vec3 direction = normalize( vWorldDirection );
	vec2 sampleUV = equirectUv( direction );
	gl_FragColor = texture2D( tEquirect, sampleUV );
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,Um=`uniform float scale;
attribute float lineDistance;
varying float vLineDistance;
#include <common>
#include <uv_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	vLineDistance = scale * lineDistance;
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
}`,Fm=`uniform vec3 diffuse;
uniform float opacity;
uniform float dashSize;
uniform float totalSize;
varying float vLineDistance;
#include <common>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	if ( mod( vLineDistance, totalSize ) > dashSize ) {
		discard;
	}
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`,Om=`#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#if defined ( USE_ENVMAP ) || defined ( USE_SKINNING )
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinbase_vertex>
		#include <skinnormal_vertex>
		#include <defaultnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <fog_vertex>
}`,km=`uniform vec3 diffuse;
uniform float opacity;
#ifndef FLAT_SHADED
	varying vec3 vNormal;
#endif
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		reflectedLight.indirectDiffuse += lightMapTexel.rgb * lightMapIntensity * RECIPROCAL_PI;
	#else
		reflectedLight.indirectDiffuse += vec3( 1.0 );
	#endif
	#include <aomap_fragment>
	reflectedLight.indirectDiffuse *= diffuseColor.rgb;
	vec3 outgoingLight = reflectedLight.indirectDiffuse;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,Bm=`#define LAMBERT
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,zm=`#define LAMBERT
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_lambert_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_lambert_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,Hm=`#define MATCAP
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <color_pars_vertex>
#include <displacementmap_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
	vViewPosition = - mvPosition.xyz;
}`,Vm=`#define MATCAP
uniform vec3 diffuse;
uniform float opacity;
uniform sampler2D matcap;
varying vec3 vViewPosition;
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <normal_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	vec3 viewDir = normalize( vViewPosition );
	vec3 x = normalize( vec3( viewDir.z, 0.0, - viewDir.x ) );
	vec3 y = cross( viewDir, x );
	vec2 uv = vec2( dot( x, normal ), dot( y, normal ) ) * 0.495 + 0.5;
	#ifdef USE_MATCAP
		vec4 matcapColor = texture2D( matcap, uv );
	#else
		vec4 matcapColor = vec4( vec3( mix( 0.2, 0.8, uv.y ) ), 1.0 );
	#endif
	vec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,Gm=`#define NORMAL
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	varying vec3 vViewPosition;
#endif
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	vViewPosition = - mvPosition.xyz;
#endif
}`,Wm=`#define NORMAL
uniform float opacity;
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	varying vec3 vViewPosition;
#endif
#include <packing>
#include <uv_pars_fragment>
#include <normal_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( 0.0, 0.0, 0.0, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	gl_FragColor = vec4( packNormalToRGB( normal ), diffuseColor.a );
	#ifdef OPAQUE
		gl_FragColor.a = 1.0;
	#endif
}`,Xm=`#define PHONG
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,qm=`#define PHONG
uniform vec3 diffuse;
uniform vec3 emissive;
uniform vec3 specular;
uniform float shininess;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_phong_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_phong_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + reflectedLight.directSpecular + reflectedLight.indirectSpecular + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,Ym=`#define STANDARD
varying vec3 vViewPosition;
#ifdef USE_TRANSMISSION
	varying vec3 vWorldPosition;
#endif
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
#ifdef USE_TRANSMISSION
	vWorldPosition = worldPosition.xyz;
#endif
}`,Km=`#define STANDARD
#ifdef PHYSICAL
	#define IOR
	#define USE_SPECULAR
#endif
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float roughness;
uniform float metalness;
uniform float opacity;
#ifdef IOR
	uniform float ior;
#endif
#ifdef USE_SPECULAR
	uniform float specularIntensity;
	uniform vec3 specularColor;
	#ifdef USE_SPECULAR_COLORMAP
		uniform sampler2D specularColorMap;
	#endif
	#ifdef USE_SPECULAR_INTENSITYMAP
		uniform sampler2D specularIntensityMap;
	#endif
#endif
#ifdef USE_CLEARCOAT
	uniform float clearcoat;
	uniform float clearcoatRoughness;
#endif
#ifdef USE_DISPERSION
	uniform float dispersion;
#endif
#ifdef USE_IRIDESCENCE
	uniform float iridescence;
	uniform float iridescenceIOR;
	uniform float iridescenceThicknessMinimum;
	uniform float iridescenceThicknessMaximum;
#endif
#ifdef USE_SHEEN
	uniform vec3 sheenColor;
	uniform float sheenRoughness;
	#ifdef USE_SHEEN_COLORMAP
		uniform sampler2D sheenColorMap;
	#endif
	#ifdef USE_SHEEN_ROUGHNESSMAP
		uniform sampler2D sheenRoughnessMap;
	#endif
#endif
#ifdef USE_ANISOTROPY
	uniform vec2 anisotropyVector;
	#ifdef USE_ANISOTROPYMAP
		uniform sampler2D anisotropyMap;
	#endif
#endif
varying vec3 vViewPosition;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <iridescence_fragment>
#include <cube_uv_reflection_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_physical_pars_fragment>
#include <fog_pars_fragment>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_physical_pars_fragment>
#include <transmission_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <clearcoat_pars_fragment>
#include <iridescence_pars_fragment>
#include <roughnessmap_pars_fragment>
#include <metalnessmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <roughnessmap_fragment>
	#include <metalnessmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <clearcoat_normal_fragment_begin>
	#include <clearcoat_normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_physical_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 totalDiffuse = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse;
	vec3 totalSpecular = reflectedLight.directSpecular + reflectedLight.indirectSpecular;
	#include <transmission_fragment>
	vec3 outgoingLight = totalDiffuse + totalSpecular + totalEmissiveRadiance;
	#ifdef USE_SHEEN
		float sheenEnergyComp = 1.0 - 0.157 * max3( material.sheenColor );
		outgoingLight = outgoingLight * sheenEnergyComp + sheenSpecularDirect + sheenSpecularIndirect;
	#endif
	#ifdef USE_CLEARCOAT
		float dotNVcc = saturate( dot( geometryClearcoatNormal, geometryViewDir ) );
		vec3 Fcc = F_Schlick( material.clearcoatF0, material.clearcoatF90, dotNVcc );
		outgoingLight = outgoingLight * ( 1.0 - material.clearcoat * Fcc ) + ( clearcoatSpecularDirect + clearcoatSpecularIndirect ) * material.clearcoat;
	#endif
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,$m=`#define TOON
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,jm=`#define TOON
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <gradientmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_toon_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_toon_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,Zm=`uniform float size;
uniform float scale;
#include <common>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
#ifdef USE_POINTS_UV
	varying vec2 vUv;
	uniform mat3 uvTransform;
#endif
void main() {
	#ifdef USE_POINTS_UV
		vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	#endif
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>
	gl_PointSize = size;
	#ifdef USE_SIZEATTENUATION
		bool isPerspective = isPerspectiveMatrix( projectionMatrix );
		if ( isPerspective ) gl_PointSize *= ( scale / - mvPosition.z );
	#endif
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <fog_vertex>
}`,Jm=`uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <color_pars_fragment>
#include <map_particle_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_particle_fragment>
	#include <color_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`,Qm=`#include <common>
#include <batching_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <shadowmap_pars_vertex>
void main() {
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,tg=`uniform vec3 color;
uniform float opacity;
#include <common>
#include <packing>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <logdepthbuf_pars_fragment>
#include <shadowmap_pars_fragment>
#include <shadowmask_pars_fragment>
void main() {
	#include <logdepthbuf_fragment>
	gl_FragColor = vec4( color, opacity * ( 1.0 - getShadowMask() ) );
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
}`,eg=`uniform float rotation;
uniform vec2 center;
#include <common>
#include <uv_pars_vertex>
#include <fog_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	vec4 mvPosition = modelViewMatrix[ 3 ];
	vec2 scale = vec2( length( modelMatrix[ 0 ].xyz ), length( modelMatrix[ 1 ].xyz ) );
	#ifndef USE_SIZEATTENUATION
		bool isPerspective = isPerspectiveMatrix( projectionMatrix );
		if ( isPerspective ) scale *= - mvPosition.z;
	#endif
	vec2 alignedPosition = ( position.xy - ( center - vec2( 0.5 ) ) ) * scale;
	vec2 rotatedPosition;
	rotatedPosition.x = cos( rotation ) * alignedPosition.x - sin( rotation ) * alignedPosition.y;
	rotatedPosition.y = sin( rotation ) * alignedPosition.x + cos( rotation ) * alignedPosition.y;
	mvPosition.xy += rotatedPosition;
	gl_Position = projectionMatrix * mvPosition;
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
}`,ng=`uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
}`,Ot={alphahash_fragment:wf,alphahash_pars_fragment:Tf,alphamap_fragment:Ef,alphamap_pars_fragment:Af,alphatest_fragment:Rf,alphatest_pars_fragment:Cf,aomap_fragment:Pf,aomap_pars_fragment:Lf,batching_pars_vertex:If,batching_vertex:Df,begin_vertex:Nf,beginnormal_vertex:Uf,bsdfs:Ff,iridescence_fragment:Of,bumpmap_pars_fragment:kf,clipping_planes_fragment:Bf,clipping_planes_pars_fragment:zf,clipping_planes_pars_vertex:Hf,clipping_planes_vertex:Vf,color_fragment:Gf,color_pars_fragment:Wf,color_pars_vertex:Xf,color_vertex:qf,common:Yf,cube_uv_reflection_fragment:Kf,defaultnormal_vertex:$f,displacementmap_pars_vertex:jf,displacementmap_vertex:Zf,emissivemap_fragment:Jf,emissivemap_pars_fragment:Qf,colorspace_fragment:tp,colorspace_pars_fragment:ep,envmap_fragment:np,envmap_common_pars_fragment:ip,envmap_pars_fragment:sp,envmap_pars_vertex:rp,envmap_physical_pars_fragment:gp,envmap_vertex:ap,fog_vertex:op,fog_pars_vertex:lp,fog_fragment:cp,fog_pars_fragment:hp,gradientmap_pars_fragment:up,lightmap_pars_fragment:dp,lights_lambert_fragment:fp,lights_lambert_pars_fragment:pp,lights_pars_begin:mp,lights_toon_fragment:vp,lights_toon_pars_fragment:_p,lights_phong_fragment:xp,lights_phong_pars_fragment:yp,lights_physical_fragment:Mp,lights_physical_pars_fragment:bp,lights_fragment_begin:Sp,lights_fragment_maps:wp,lights_fragment_end:Tp,logdepthbuf_fragment:Ep,logdepthbuf_pars_fragment:Ap,logdepthbuf_pars_vertex:Rp,logdepthbuf_vertex:Cp,map_fragment:Pp,map_pars_fragment:Lp,map_particle_fragment:Ip,map_particle_pars_fragment:Dp,metalnessmap_fragment:Np,metalnessmap_pars_fragment:Up,morphinstance_vertex:Fp,morphcolor_vertex:Op,morphnormal_vertex:kp,morphtarget_pars_vertex:Bp,morphtarget_vertex:zp,normal_fragment_begin:Hp,normal_fragment_maps:Vp,normal_pars_fragment:Gp,normal_pars_vertex:Wp,normal_vertex:Xp,normalmap_pars_fragment:qp,clearcoat_normal_fragment_begin:Yp,clearcoat_normal_fragment_maps:Kp,clearcoat_pars_fragment:$p,iridescence_pars_fragment:jp,opaque_fragment:Zp,packing:Jp,premultiplied_alpha_fragment:Qp,project_vertex:tm,dithering_fragment:em,dithering_pars_fragment:nm,roughnessmap_fragment:im,roughnessmap_pars_fragment:sm,shadowmap_pars_fragment:rm,shadowmap_pars_vertex:am,shadowmap_vertex:om,shadowmask_pars_fragment:lm,skinbase_vertex:cm,skinning_pars_vertex:hm,skinning_vertex:um,skinnormal_vertex:dm,specularmap_fragment:fm,specularmap_pars_fragment:pm,tonemapping_fragment:mm,tonemapping_pars_fragment:gm,transmission_fragment:vm,transmission_pars_fragment:_m,uv_pars_fragment:xm,uv_pars_vertex:ym,uv_vertex:Mm,worldpos_vertex:bm,background_vert:Sm,background_frag:wm,backgroundCube_vert:Tm,backgroundCube_frag:Em,cube_vert:Am,cube_frag:Rm,depth_vert:Cm,depth_frag:Pm,distanceRGBA_vert:Lm,distanceRGBA_frag:Im,equirect_vert:Dm,equirect_frag:Nm,linedashed_vert:Um,linedashed_frag:Fm,meshbasic_vert:Om,meshbasic_frag:km,meshlambert_vert:Bm,meshlambert_frag:zm,meshmatcap_vert:Hm,meshmatcap_frag:Vm,meshnormal_vert:Gm,meshnormal_frag:Wm,meshphong_vert:Xm,meshphong_frag:qm,meshphysical_vert:Ym,meshphysical_frag:Km,meshtoon_vert:$m,meshtoon_frag:jm,points_vert:Zm,points_frag:Jm,shadow_vert:Qm,shadow_frag:tg,sprite_vert:eg,sprite_frag:ng},st={common:{diffuse:{value:new dt(16777215)},opacity:{value:1},map:{value:null},mapTransform:{value:new Ut},alphaMap:{value:null},alphaMapTransform:{value:new Ut},alphaTest:{value:0}},specularmap:{specularMap:{value:null},specularMapTransform:{value:new Ut}},envmap:{envMap:{value:null},envMapRotation:{value:new Ut},flipEnvMap:{value:-1},reflectivity:{value:1},ior:{value:1.5},refractionRatio:{value:.98}},aomap:{aoMap:{value:null},aoMapIntensity:{value:1},aoMapTransform:{value:new Ut}},lightmap:{lightMap:{value:null},lightMapIntensity:{value:1},lightMapTransform:{value:new Ut}},bumpmap:{bumpMap:{value:null},bumpMapTransform:{value:new Ut},bumpScale:{value:1}},normalmap:{normalMap:{value:null},normalMapTransform:{value:new Ut},normalScale:{value:new nt(1,1)}},displacementmap:{displacementMap:{value:null},displacementMapTransform:{value:new Ut},displacementScale:{value:1},displacementBias:{value:0}},emissivemap:{emissiveMap:{value:null},emissiveMapTransform:{value:new Ut}},metalnessmap:{metalnessMap:{value:null},metalnessMapTransform:{value:new Ut}},roughnessmap:{roughnessMap:{value:null},roughnessMapTransform:{value:new Ut}},gradientmap:{gradientMap:{value:null}},fog:{fogDensity:{value:25e-5},fogNear:{value:1},fogFar:{value:2e3},fogColor:{value:new dt(16777215)}},lights:{ambientLightColor:{value:[]},lightProbe:{value:[]},directionalLights:{value:[],properties:{direction:{},color:{}}},directionalLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{}}},directionalShadowMap:{value:[]},directionalShadowMatrix:{value:[]},spotLights:{value:[],properties:{color:{},position:{},direction:{},distance:{},coneCos:{},penumbraCos:{},decay:{}}},spotLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{}}},spotLightMap:{value:[]},spotShadowMap:{value:[]},spotLightMatrix:{value:[]},pointLights:{value:[],properties:{color:{},position:{},decay:{},distance:{}}},pointLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{},shadowCameraNear:{},shadowCameraFar:{}}},pointShadowMap:{value:[]},pointShadowMatrix:{value:[]},hemisphereLights:{value:[],properties:{direction:{},skyColor:{},groundColor:{}}},rectAreaLights:{value:[],properties:{color:{},position:{},width:{},height:{}}},ltc_1:{value:null},ltc_2:{value:null}},points:{diffuse:{value:new dt(16777215)},opacity:{value:1},size:{value:1},scale:{value:1},map:{value:null},alphaMap:{value:null},alphaMapTransform:{value:new Ut},alphaTest:{value:0},uvTransform:{value:new Ut}},sprite:{diffuse:{value:new dt(16777215)},opacity:{value:1},center:{value:new nt(.5,.5)},rotation:{value:0},map:{value:null},mapTransform:{value:new Ut},alphaMap:{value:null},alphaMapTransform:{value:new Ut},alphaTest:{value:0}}},Rn={basic:{uniforms:Ge([st.common,st.specularmap,st.envmap,st.aomap,st.lightmap,st.fog]),vertexShader:Ot.meshbasic_vert,fragmentShader:Ot.meshbasic_frag},lambert:{uniforms:Ge([st.common,st.specularmap,st.envmap,st.aomap,st.lightmap,st.emissivemap,st.bumpmap,st.normalmap,st.displacementmap,st.fog,st.lights,{emissive:{value:new dt(0)}}]),vertexShader:Ot.meshlambert_vert,fragmentShader:Ot.meshlambert_frag},phong:{uniforms:Ge([st.common,st.specularmap,st.envmap,st.aomap,st.lightmap,st.emissivemap,st.bumpmap,st.normalmap,st.displacementmap,st.fog,st.lights,{emissive:{value:new dt(0)},specular:{value:new dt(1118481)},shininess:{value:30}}]),vertexShader:Ot.meshphong_vert,fragmentShader:Ot.meshphong_frag},standard:{uniforms:Ge([st.common,st.envmap,st.aomap,st.lightmap,st.emissivemap,st.bumpmap,st.normalmap,st.displacementmap,st.roughnessmap,st.metalnessmap,st.fog,st.lights,{emissive:{value:new dt(0)},roughness:{value:1},metalness:{value:0},envMapIntensity:{value:1}}]),vertexShader:Ot.meshphysical_vert,fragmentShader:Ot.meshphysical_frag},toon:{uniforms:Ge([st.common,st.aomap,st.lightmap,st.emissivemap,st.bumpmap,st.normalmap,st.displacementmap,st.gradientmap,st.fog,st.lights,{emissive:{value:new dt(0)}}]),vertexShader:Ot.meshtoon_vert,fragmentShader:Ot.meshtoon_frag},matcap:{uniforms:Ge([st.common,st.bumpmap,st.normalmap,st.displacementmap,st.fog,{matcap:{value:null}}]),vertexShader:Ot.meshmatcap_vert,fragmentShader:Ot.meshmatcap_frag},points:{uniforms:Ge([st.points,st.fog]),vertexShader:Ot.points_vert,fragmentShader:Ot.points_frag},dashed:{uniforms:Ge([st.common,st.fog,{scale:{value:1},dashSize:{value:1},totalSize:{value:2}}]),vertexShader:Ot.linedashed_vert,fragmentShader:Ot.linedashed_frag},depth:{uniforms:Ge([st.common,st.displacementmap]),vertexShader:Ot.depth_vert,fragmentShader:Ot.depth_frag},normal:{uniforms:Ge([st.common,st.bumpmap,st.normalmap,st.displacementmap,{opacity:{value:1}}]),vertexShader:Ot.meshnormal_vert,fragmentShader:Ot.meshnormal_frag},sprite:{uniforms:Ge([st.sprite,st.fog]),vertexShader:Ot.sprite_vert,fragmentShader:Ot.sprite_frag},background:{uniforms:{uvTransform:{value:new Ut},t2D:{value:null},backgroundIntensity:{value:1}},vertexShader:Ot.background_vert,fragmentShader:Ot.background_frag},backgroundCube:{uniforms:{envMap:{value:null},flipEnvMap:{value:-1},backgroundBlurriness:{value:0},backgroundIntensity:{value:1},backgroundRotation:{value:new Ut}},vertexShader:Ot.backgroundCube_vert,fragmentShader:Ot.backgroundCube_frag},cube:{uniforms:{tCube:{value:null},tFlip:{value:-1},opacity:{value:1}},vertexShader:Ot.cube_vert,fragmentShader:Ot.cube_frag},equirect:{uniforms:{tEquirect:{value:null}},vertexShader:Ot.equirect_vert,fragmentShader:Ot.equirect_frag},distanceRGBA:{uniforms:Ge([st.common,st.displacementmap,{referencePosition:{value:new P},nearDistance:{value:1},farDistance:{value:1e3}}]),vertexShader:Ot.distanceRGBA_vert,fragmentShader:Ot.distanceRGBA_frag},shadow:{uniforms:Ge([st.lights,st.fog,{color:{value:new dt(0)},opacity:{value:1}}]),vertexShader:Ot.shadow_vert,fragmentShader:Ot.shadow_frag}};Rn.physical={uniforms:Ge([Rn.standard.uniforms,{clearcoat:{value:0},clearcoatMap:{value:null},clearcoatMapTransform:{value:new Ut},clearcoatNormalMap:{value:null},clearcoatNormalMapTransform:{value:new Ut},clearcoatNormalScale:{value:new nt(1,1)},clearcoatRoughness:{value:0},clearcoatRoughnessMap:{value:null},clearcoatRoughnessMapTransform:{value:new Ut},dispersion:{value:0},iridescence:{value:0},iridescenceMap:{value:null},iridescenceMapTransform:{value:new Ut},iridescenceIOR:{value:1.3},iridescenceThicknessMinimum:{value:100},iridescenceThicknessMaximum:{value:400},iridescenceThicknessMap:{value:null},iridescenceThicknessMapTransform:{value:new Ut},sheen:{value:0},sheenColor:{value:new dt(0)},sheenColorMap:{value:null},sheenColorMapTransform:{value:new Ut},sheenRoughness:{value:1},sheenRoughnessMap:{value:null},sheenRoughnessMapTransform:{value:new Ut},transmission:{value:0},transmissionMap:{value:null},transmissionMapTransform:{value:new Ut},transmissionSamplerSize:{value:new nt},transmissionSamplerMap:{value:null},thickness:{value:0},thicknessMap:{value:null},thicknessMapTransform:{value:new Ut},attenuationDistance:{value:0},attenuationColor:{value:new dt(0)},specularColor:{value:new dt(1,1,1)},specularColorMap:{value:null},specularColorMapTransform:{value:new Ut},specularIntensity:{value:1},specularIntensityMap:{value:null},specularIntensityMapTransform:{value:new Ut},anisotropyVector:{value:new nt},anisotropyMap:{value:null},anisotropyMapTransform:{value:new Ut}}]),vertexShader:Ot.meshphysical_vert,fragmentShader:Ot.meshphysical_frag};const Er={r:0,b:0,g:0},Ti=new En,ig=new It;function sg(r,t,e,n,i,s,a){const o=new dt(0);let l=s===!0?0:1,c,h,u=null,d=0,f=null;function m(x){let y=x.isScene===!0?x.background:null;return y&&y.isTexture&&(y=(x.backgroundBlurriness>0?e:t).get(y)),y}function v(x){let y=!1;const _=m(x);_===null?p(o,l):_&&_.isColor&&(p(_,1),y=!0);const I=r.xr.getEnvironmentBlendMode();I==="additive"?n.buffers.color.setClear(0,0,0,1,a):I==="alpha-blend"&&n.buffers.color.setClear(0,0,0,0,a),(r.autoClear||y)&&(n.buffers.depth.setTest(!0),n.buffers.depth.setMask(!0),n.buffers.color.setMask(!0),r.clear(r.autoClearColor,r.autoClearDepth,r.autoClearStencil))}function g(x,y){const _=m(y);_&&(_.isCubeTexture||_.mapping===ia)?(h===void 0&&(h=new Rt(new xe(1,1,1),new Te({name:"BackgroundCubeMaterial",uniforms:ds(Rn.backgroundCube.uniforms),vertexShader:Rn.backgroundCube.vertexShader,fragmentShader:Rn.backgroundCube.fragmentShader,side:$e,depthTest:!1,depthWrite:!1,fog:!1})),h.geometry.deleteAttribute("normal"),h.geometry.deleteAttribute("uv"),h.onBeforeRender=function(I,E,A){this.matrixWorld.copyPosition(A.matrixWorld)},Object.defineProperty(h.material,"envMap",{get:function(){return this.uniforms.envMap.value}}),i.update(h)),Ti.copy(y.backgroundRotation),Ti.x*=-1,Ti.y*=-1,Ti.z*=-1,_.isCubeTexture&&_.isRenderTargetTexture===!1&&(Ti.y*=-1,Ti.z*=-1),h.material.uniforms.envMap.value=_,h.material.uniforms.flipEnvMap.value=_.isCubeTexture&&_.isRenderTargetTexture===!1?-1:1,h.material.uniforms.backgroundBlurriness.value=y.backgroundBlurriness,h.material.uniforms.backgroundIntensity.value=y.backgroundIntensity,h.material.uniforms.backgroundRotation.value.setFromMatrix4(ig.makeRotationFromEuler(Ti)),h.material.toneMapped=Ht.getTransfer(_.colorSpace)!==se,(u!==_||d!==_.version||f!==r.toneMapping)&&(h.material.needsUpdate=!0,u=_,d=_.version,f=r.toneMapping),h.layers.enableAll(),x.unshift(h,h.geometry,h.material,0,0,null)):_&&_.isTexture&&(c===void 0&&(c=new Rt(new We(2,2),new Te({name:"BackgroundMaterial",uniforms:ds(Rn.background.uniforms),vertexShader:Rn.background.vertexShader,fragmentShader:Rn.background.fragmentShader,side:Zn,depthTest:!1,depthWrite:!1,fog:!1})),c.geometry.deleteAttribute("normal"),Object.defineProperty(c.material,"map",{get:function(){return this.uniforms.t2D.value}}),i.update(c)),c.material.uniforms.t2D.value=_,c.material.uniforms.backgroundIntensity.value=y.backgroundIntensity,c.material.toneMapped=Ht.getTransfer(_.colorSpace)!==se,_.matrixAutoUpdate===!0&&_.updateMatrix(),c.material.uniforms.uvTransform.value.copy(_.matrix),(u!==_||d!==_.version||f!==r.toneMapping)&&(c.material.needsUpdate=!0,u=_,d=_.version,f=r.toneMapping),c.layers.enableAll(),x.unshift(c,c.geometry,c.material,0,0,null))}function p(x,y){x.getRGB(Er,su(r)),n.buffers.color.setClear(Er.r,Er.g,Er.b,y,a)}return{getClearColor:function(){return o},setClearColor:function(x,y=1){o.set(x),l=y,p(o,l)},getClearAlpha:function(){return l},setClearAlpha:function(x){l=x,p(o,l)},render:v,addToRenderList:g}}function rg(r,t){const e=r.getParameter(r.MAX_VERTEX_ATTRIBS),n={},i=d(null);let s=i,a=!1;function o(M,L,z,R,B){let j=!1;const X=u(R,z,L);s!==X&&(s=X,c(s.object)),j=f(M,R,z,B),j&&m(M,R,z,B),B!==null&&t.update(B,r.ELEMENT_ARRAY_BUFFER),(j||a)&&(a=!1,_(M,L,z,R),B!==null&&r.bindBuffer(r.ELEMENT_ARRAY_BUFFER,t.get(B).buffer))}function l(){return r.createVertexArray()}function c(M){return r.bindVertexArray(M)}function h(M){return r.deleteVertexArray(M)}function u(M,L,z){const R=z.wireframe===!0;let B=n[M.id];B===void 0&&(B={},n[M.id]=B);let j=B[L.id];j===void 0&&(j={},B[L.id]=j);let X=j[R];return X===void 0&&(X=d(l()),j[R]=X),X}function d(M){const L=[],z=[],R=[];for(let B=0;B<e;B++)L[B]=0,z[B]=0,R[B]=0;return{geometry:null,program:null,wireframe:!1,newAttributes:L,enabledAttributes:z,attributeDivisors:R,object:M,attributes:{},index:null}}function f(M,L,z,R){const B=s.attributes,j=L.attributes;let X=0;const Q=z.getAttributes();for(const G in Q)if(Q[G].location>=0){const lt=B[G];let St=j[G];if(St===void 0&&(G==="instanceMatrix"&&M.instanceMatrix&&(St=M.instanceMatrix),G==="instanceColor"&&M.instanceColor&&(St=M.instanceColor)),lt===void 0||lt.attribute!==St||St&&lt.data!==St.data)return!0;X++}return s.attributesNum!==X||s.index!==R}function m(M,L,z,R){const B={},j=L.attributes;let X=0;const Q=z.getAttributes();for(const G in Q)if(Q[G].location>=0){let lt=j[G];lt===void 0&&(G==="instanceMatrix"&&M.instanceMatrix&&(lt=M.instanceMatrix),G==="instanceColor"&&M.instanceColor&&(lt=M.instanceColor));const St={};St.attribute=lt,lt&&lt.data&&(St.data=lt.data),B[G]=St,X++}s.attributes=B,s.attributesNum=X,s.index=R}function v(){const M=s.newAttributes;for(let L=0,z=M.length;L<z;L++)M[L]=0}function g(M){p(M,0)}function p(M,L){const z=s.newAttributes,R=s.enabledAttributes,B=s.attributeDivisors;z[M]=1,R[M]===0&&(r.enableVertexAttribArray(M),R[M]=1),B[M]!==L&&(r.vertexAttribDivisor(M,L),B[M]=L)}function x(){const M=s.newAttributes,L=s.enabledAttributes;for(let z=0,R=L.length;z<R;z++)L[z]!==M[z]&&(r.disableVertexAttribArray(z),L[z]=0)}function y(M,L,z,R,B,j,X){X===!0?r.vertexAttribIPointer(M,L,z,B,j):r.vertexAttribPointer(M,L,z,R,B,j)}function _(M,L,z,R){v();const B=R.attributes,j=z.getAttributes(),X=L.defaultAttributeValues;for(const Q in j){const G=j[Q];if(G.location>=0){let it=B[Q];if(it===void 0&&(Q==="instanceMatrix"&&M.instanceMatrix&&(it=M.instanceMatrix),Q==="instanceColor"&&M.instanceColor&&(it=M.instanceColor)),it!==void 0){const lt=it.normalized,St=it.itemSize,kt=t.get(it);if(kt===void 0)continue;const ce=kt.buffer,Y=kt.type,et=kt.bytesPerElement,yt=Y===r.INT||Y===r.UNSIGNED_INT||it.gpuType===il;if(it.isInterleavedBufferAttribute){const at=it.data,At=at.stride,Lt=it.offset;if(at.isInstancedInterleavedBuffer){for(let Bt=0;Bt<G.locationSize;Bt++)p(G.location+Bt,at.meshPerAttribute);M.isInstancedMesh!==!0&&R._maxInstanceCount===void 0&&(R._maxInstanceCount=at.meshPerAttribute*at.count)}else for(let Bt=0;Bt<G.locationSize;Bt++)g(G.location+Bt);r.bindBuffer(r.ARRAY_BUFFER,ce);for(let Bt=0;Bt<G.locationSize;Bt++)y(G.location+Bt,St/G.locationSize,Y,lt,At*et,(Lt+St/G.locationSize*Bt)*et,yt)}else{if(it.isInstancedBufferAttribute){for(let at=0;at<G.locationSize;at++)p(G.location+at,it.meshPerAttribute);M.isInstancedMesh!==!0&&R._maxInstanceCount===void 0&&(R._maxInstanceCount=it.meshPerAttribute*it.count)}else for(let at=0;at<G.locationSize;at++)g(G.location+at);r.bindBuffer(r.ARRAY_BUFFER,ce);for(let at=0;at<G.locationSize;at++)y(G.location+at,St/G.locationSize,Y,lt,St*et,St/G.locationSize*at*et,yt)}}else if(X!==void 0){const lt=X[Q];if(lt!==void 0)switch(lt.length){case 2:r.vertexAttrib2fv(G.location,lt);break;case 3:r.vertexAttrib3fv(G.location,lt);break;case 4:r.vertexAttrib4fv(G.location,lt);break;default:r.vertexAttrib1fv(G.location,lt)}}}}x()}function I(){C();for(const M in n){const L=n[M];for(const z in L){const R=L[z];for(const B in R)h(R[B].object),delete R[B];delete L[z]}delete n[M]}}function E(M){if(n[M.id]===void 0)return;const L=n[M.id];for(const z in L){const R=L[z];for(const B in R)h(R[B].object),delete R[B];delete L[z]}delete n[M.id]}function A(M){for(const L in n){const z=n[L];if(z[M.id]===void 0)continue;const R=z[M.id];for(const B in R)h(R[B].object),delete R[B];delete z[M.id]}}function C(){b(),a=!0,s!==i&&(s=i,c(s.object))}function b(){i.geometry=null,i.program=null,i.wireframe=!1}return{setup:o,reset:C,resetDefaultState:b,dispose:I,releaseStatesOfGeometry:E,releaseStatesOfProgram:A,initAttributes:v,enableAttribute:g,disableUnusedAttributes:x}}function ag(r,t,e){let n;function i(c){n=c}function s(c,h){r.drawArrays(n,c,h),e.update(h,n,1)}function a(c,h,u){u!==0&&(r.drawArraysInstanced(n,c,h,u),e.update(h,n,u))}function o(c,h,u){if(u===0)return;t.get("WEBGL_multi_draw").multiDrawArraysWEBGL(n,c,0,h,0,u);let f=0;for(let m=0;m<u;m++)f+=h[m];e.update(f,n,1)}function l(c,h,u,d){if(u===0)return;const f=t.get("WEBGL_multi_draw");if(f===null)for(let m=0;m<c.length;m++)a(c[m],h[m],d[m]);else{f.multiDrawArraysInstancedWEBGL(n,c,0,h,0,d,0,u);let m=0;for(let v=0;v<u;v++)m+=h[v]*d[v];e.update(m,n,1)}}this.setMode=i,this.render=s,this.renderInstances=a,this.renderMultiDraw=o,this.renderMultiDrawInstances=l}function og(r,t,e,n){let i;function s(){if(i!==void 0)return i;if(t.has("EXT_texture_filter_anisotropic")===!0){const A=t.get("EXT_texture_filter_anisotropic");i=r.getParameter(A.MAX_TEXTURE_MAX_ANISOTROPY_EXT)}else i=0;return i}function a(A){return!(A!==un&&n.convert(A)!==r.getParameter(r.IMPLEMENTATION_COLOR_READ_FORMAT))}function o(A){const C=A===Pn&&(t.has("EXT_color_buffer_half_float")||t.has("EXT_color_buffer_float"));return!(A!==Jn&&n.convert(A)!==r.getParameter(r.IMPLEMENTATION_COLOR_READ_TYPE)&&A!==Sn&&!C)}function l(A){if(A==="highp"){if(r.getShaderPrecisionFormat(r.VERTEX_SHADER,r.HIGH_FLOAT).precision>0&&r.getShaderPrecisionFormat(r.FRAGMENT_SHADER,r.HIGH_FLOAT).precision>0)return"highp";A="mediump"}return A==="mediump"&&r.getShaderPrecisionFormat(r.VERTEX_SHADER,r.MEDIUM_FLOAT).precision>0&&r.getShaderPrecisionFormat(r.FRAGMENT_SHADER,r.MEDIUM_FLOAT).precision>0?"mediump":"lowp"}let c=e.precision!==void 0?e.precision:"highp";const h=l(c);h!==c&&(console.warn("THREE.WebGLRenderer:",c,"not supported, using",h,"instead."),c=h);const u=e.logarithmicDepthBuffer===!0,d=e.reverseDepthBuffer===!0&&t.has("EXT_clip_control"),f=r.getParameter(r.MAX_TEXTURE_IMAGE_UNITS),m=r.getParameter(r.MAX_VERTEX_TEXTURE_IMAGE_UNITS),v=r.getParameter(r.MAX_TEXTURE_SIZE),g=r.getParameter(r.MAX_CUBE_MAP_TEXTURE_SIZE),p=r.getParameter(r.MAX_VERTEX_ATTRIBS),x=r.getParameter(r.MAX_VERTEX_UNIFORM_VECTORS),y=r.getParameter(r.MAX_VARYING_VECTORS),_=r.getParameter(r.MAX_FRAGMENT_UNIFORM_VECTORS),I=m>0,E=r.getParameter(r.MAX_SAMPLES);return{isWebGL2:!0,getMaxAnisotropy:s,getMaxPrecision:l,textureFormatReadable:a,textureTypeReadable:o,precision:c,logarithmicDepthBuffer:u,reverseDepthBuffer:d,maxTextures:f,maxVertexTextures:m,maxTextureSize:v,maxCubemapSize:g,maxAttributes:p,maxVertexUniforms:x,maxVaryings:y,maxFragmentUniforms:_,vertexTextures:I,maxSamples:E}}function lg(r){const t=this;let e=null,n=0,i=!1,s=!1;const a=new Ri,o=new Ut,l={value:null,needsUpdate:!1};this.uniform=l,this.numPlanes=0,this.numIntersection=0,this.init=function(u,d){const f=u.length!==0||d||n!==0||i;return i=d,n=u.length,f},this.beginShadows=function(){s=!0,h(null)},this.endShadows=function(){s=!1},this.setGlobalState=function(u,d){e=h(u,d,0)},this.setState=function(u,d,f){const m=u.clippingPlanes,v=u.clipIntersection,g=u.clipShadows,p=r.get(u);if(!i||m===null||m.length===0||s&&!g)s?h(null):c();else{const x=s?0:n,y=x*4;let _=p.clippingState||null;l.value=_,_=h(m,d,y,f);for(let I=0;I!==y;++I)_[I]=e[I];p.clippingState=_,this.numIntersection=v?this.numPlanes:0,this.numPlanes+=x}};function c(){l.value!==e&&(l.value=e,l.needsUpdate=n>0),t.numPlanes=n,t.numIntersection=0}function h(u,d,f,m){const v=u!==null?u.length:0;let g=null;if(v!==0){if(g=l.value,m!==!0||g===null){const p=f+v*4,x=d.matrixWorldInverse;o.getNormalMatrix(x),(g===null||g.length<p)&&(g=new Float32Array(p));for(let y=0,_=f;y!==v;++y,_+=4)a.copy(u[y]).applyMatrix4(x,o),a.normal.toArray(g,_),g[_+3]=a.constant}l.value=g,l.needsUpdate=!0}return t.numPlanes=v,t.numIntersection=0,g}}function cg(r){let t=new WeakMap;function e(a,o){return o===uo?a.mapping=os:o===fo&&(a.mapping=ls),a}function n(a){if(a&&a.isTexture){const o=a.mapping;if(o===uo||o===fo)if(t.has(a)){const l=t.get(a).texture;return e(l,a.mapping)}else{const l=a.image;if(l&&l.height>0){const c=new yf(l.height);return c.fromEquirectangularTexture(r,a),t.set(a,c),a.addEventListener("dispose",i),e(c.texture,a.mapping)}else return null}}return a}function i(a){const o=a.target;o.removeEventListener("dispose",i);const l=t.get(o);l!==void 0&&(t.delete(o),l.dispose())}function s(){t=new WeakMap}return{get:n,dispose:s}}class aa extends ru{constructor(t=-1,e=1,n=1,i=-1,s=.1,a=2e3){super(),this.isOrthographicCamera=!0,this.type="OrthographicCamera",this.zoom=1,this.view=null,this.left=t,this.right=e,this.top=n,this.bottom=i,this.near=s,this.far=a,this.updateProjectionMatrix()}copy(t,e){return super.copy(t,e),this.left=t.left,this.right=t.right,this.top=t.top,this.bottom=t.bottom,this.near=t.near,this.far=t.far,this.zoom=t.zoom,this.view=t.view===null?null:Object.assign({},t.view),this}setViewOffset(t,e,n,i,s,a){this.view===null&&(this.view={enabled:!0,fullWidth:1,fullHeight:1,offsetX:0,offsetY:0,width:1,height:1}),this.view.enabled=!0,this.view.fullWidth=t,this.view.fullHeight=e,this.view.offsetX=n,this.view.offsetY=i,this.view.width=s,this.view.height=a,this.updateProjectionMatrix()}clearViewOffset(){this.view!==null&&(this.view.enabled=!1),this.updateProjectionMatrix()}updateProjectionMatrix(){const t=(this.right-this.left)/(2*this.zoom),e=(this.top-this.bottom)/(2*this.zoom),n=(this.right+this.left)/2,i=(this.top+this.bottom)/2;let s=n-t,a=n+t,o=i+e,l=i-e;if(this.view!==null&&this.view.enabled){const c=(this.right-this.left)/this.view.fullWidth/this.zoom,h=(this.top-this.bottom)/this.view.fullHeight/this.zoom;s+=c*this.view.offsetX,a=s+c*this.view.width,o-=h*this.view.offsetY,l=o-h*this.view.height}this.projectionMatrix.makeOrthographic(s,a,o,l,this.near,this.far,this.coordinateSystem),this.projectionMatrixInverse.copy(this.projectionMatrix).invert()}toJSON(t){const e=super.toJSON(t);return e.object.zoom=this.zoom,e.object.left=this.left,e.object.right=this.right,e.object.top=this.top,e.object.bottom=this.bottom,e.object.near=this.near,e.object.far=this.far,this.view!==null&&(e.object.view=Object.assign({},this.view)),e}}const es=4,pc=[.125,.215,.35,.446,.526,.582],Ii=20,Na=new aa,mc=new dt;let Ua=null,Fa=0,Oa=0,ka=!1;const Ci=(1+Math.sqrt(5))/2,Zi=1/Ci,gc=[new P(-Ci,Zi,0),new P(Ci,Zi,0),new P(-Zi,0,Ci),new P(Zi,0,Ci),new P(0,Ci,-Zi),new P(0,Ci,Zi),new P(-1,1,-1),new P(1,1,-1),new P(-1,1,1),new P(1,1,1)];class vc{constructor(t){this._renderer=t,this._pingPongRenderTarget=null,this._lodMax=0,this._cubeSize=0,this._lodPlanes=[],this._sizeLods=[],this._sigmas=[],this._blurMaterial=null,this._cubemapMaterial=null,this._equirectMaterial=null,this._compileMaterial(this._blurMaterial)}fromScene(t,e=0,n=.1,i=100){Ua=this._renderer.getRenderTarget(),Fa=this._renderer.getActiveCubeFace(),Oa=this._renderer.getActiveMipmapLevel(),ka=this._renderer.xr.enabled,this._renderer.xr.enabled=!1,this._setSize(256);const s=this._allocateTargets();return s.depthBuffer=!0,this._sceneToCubeUV(t,n,i,s),e>0&&this._blur(s,0,0,e),this._applyPMREM(s),this._cleanup(s),s}fromEquirectangular(t,e=null){return this._fromTexture(t,e)}fromCubemap(t,e=null){return this._fromTexture(t,e)}compileCubemapShader(){this._cubemapMaterial===null&&(this._cubemapMaterial=yc(),this._compileMaterial(this._cubemapMaterial))}compileEquirectangularShader(){this._equirectMaterial===null&&(this._equirectMaterial=xc(),this._compileMaterial(this._equirectMaterial))}dispose(){this._dispose(),this._cubemapMaterial!==null&&this._cubemapMaterial.dispose(),this._equirectMaterial!==null&&this._equirectMaterial.dispose()}_setSize(t){this._lodMax=Math.floor(Math.log2(t)),this._cubeSize=Math.pow(2,this._lodMax)}_dispose(){this._blurMaterial!==null&&this._blurMaterial.dispose(),this._pingPongRenderTarget!==null&&this._pingPongRenderTarget.dispose();for(let t=0;t<this._lodPlanes.length;t++)this._lodPlanes[t].dispose()}_cleanup(t){this._renderer.setRenderTarget(Ua,Fa,Oa),this._renderer.xr.enabled=ka,t.scissorTest=!1,Ar(t,0,0,t.width,t.height)}_fromTexture(t,e){t.mapping===os||t.mapping===ls?this._setSize(t.image.length===0?16:t.image[0].width||t.image[0].image.width):this._setSize(t.image.width/4),Ua=this._renderer.getRenderTarget(),Fa=this._renderer.getActiveCubeFace(),Oa=this._renderer.getActiveMipmapLevel(),ka=this._renderer.xr.enabled,this._renderer.xr.enabled=!1;const n=e||this._allocateTargets();return this._textureToCubeUV(t,n),this._applyPMREM(n),this._cleanup(n),n}_allocateTargets(){const t=3*Math.max(this._cubeSize,112),e=4*this._cubeSize,n={magFilter:tn,minFilter:tn,generateMipmaps:!1,type:Pn,format:un,colorSpace:qe,depthBuffer:!1},i=_c(t,e,n);if(this._pingPongRenderTarget===null||this._pingPongRenderTarget.width!==t||this._pingPongRenderTarget.height!==e){this._pingPongRenderTarget!==null&&this._dispose(),this._pingPongRenderTarget=_c(t,e,n);const{_lodMax:s}=this;({sizeLods:this._sizeLods,lodPlanes:this._lodPlanes,sigmas:this._sigmas}=hg(s)),this._blurMaterial=ug(s,t,e)}return i}_compileMaterial(t){const e=new Rt(this._lodPlanes[0],t);this._renderer.compile(e,Na)}_sceneToCubeUV(t,e,n,i){const o=new ze(90,1,e,n),l=[1,-1,1,1,1,1],c=[1,1,1,-1,-1,-1],h=this._renderer,u=h.autoClear,d=h.toneMapping;h.getClearColor(mc),h.toneMapping=gi,h.autoClear=!1;const f=new ne({name:"PMREM.Background",side:$e,depthWrite:!1,depthTest:!1}),m=new Rt(new xe,f);let v=!1;const g=t.background;g?g.isColor&&(f.color.copy(g),t.background=null,v=!0):(f.color.copy(mc),v=!0);for(let p=0;p<6;p++){const x=p%3;x===0?(o.up.set(0,l[p],0),o.lookAt(c[p],0,0)):x===1?(o.up.set(0,0,l[p]),o.lookAt(0,c[p],0)):(o.up.set(0,l[p],0),o.lookAt(0,0,c[p]));const y=this._cubeSize;Ar(i,x*y,p>2?y:0,y,y),h.setRenderTarget(i),v&&h.render(m,o),h.render(t,o)}m.geometry.dispose(),m.material.dispose(),h.toneMapping=d,h.autoClear=u,t.background=g}_textureToCubeUV(t,e){const n=this._renderer,i=t.mapping===os||t.mapping===ls;i?(this._cubemapMaterial===null&&(this._cubemapMaterial=yc()),this._cubemapMaterial.uniforms.flipEnvMap.value=t.isRenderTargetTexture===!1?-1:1):this._equirectMaterial===null&&(this._equirectMaterial=xc());const s=i?this._cubemapMaterial:this._equirectMaterial,a=new Rt(this._lodPlanes[0],s),o=s.uniforms;o.envMap.value=t;const l=this._cubeSize;Ar(e,0,0,3*l,2*l),n.setRenderTarget(e),n.render(a,Na)}_applyPMREM(t){const e=this._renderer,n=e.autoClear;e.autoClear=!1;const i=this._lodPlanes.length;for(let s=1;s<i;s++){const a=Math.sqrt(this._sigmas[s]*this._sigmas[s]-this._sigmas[s-1]*this._sigmas[s-1]),o=gc[(i-s-1)%gc.length];this._blur(t,s-1,s,a,o)}e.autoClear=n}_blur(t,e,n,i,s){const a=this._pingPongRenderTarget;this._halfBlur(t,a,e,n,i,"latitudinal",s),this._halfBlur(a,t,n,n,i,"longitudinal",s)}_halfBlur(t,e,n,i,s,a,o){const l=this._renderer,c=this._blurMaterial;a!=="latitudinal"&&a!=="longitudinal"&&console.error("blur direction must be either latitudinal or longitudinal!");const h=3,u=new Rt(this._lodPlanes[i],c),d=c.uniforms,f=this._sizeLods[n]-1,m=isFinite(s)?Math.PI/(2*f):2*Math.PI/(2*Ii-1),v=s/m,g=isFinite(s)?1+Math.floor(h*v):Ii;g>Ii&&console.warn(`sigmaRadians, ${s}, is too large and will clip, as it requested ${g} samples when the maximum is set to ${Ii}`);const p=[];let x=0;for(let A=0;A<Ii;++A){const C=A/v,b=Math.exp(-C*C/2);p.push(b),A===0?x+=b:A<g&&(x+=2*b)}for(let A=0;A<p.length;A++)p[A]=p[A]/x;d.envMap.value=t.texture,d.samples.value=g,d.weights.value=p,d.latitudinal.value=a==="latitudinal",o&&(d.poleAxis.value=o);const{_lodMax:y}=this;d.dTheta.value=m,d.mipInt.value=y-n;const _=this._sizeLods[i],I=3*_*(i>y-es?i-y+es:0),E=4*(this._cubeSize-_);Ar(e,I,E,3*_,2*_),l.setRenderTarget(e),l.render(u,Na)}}function hg(r){const t=[],e=[],n=[];let i=r;const s=r-es+1+pc.length;for(let a=0;a<s;a++){const o=Math.pow(2,i);e.push(o);let l=1/o;a>r-es?l=pc[a-r+es-1]:a===0&&(l=0),n.push(l);const c=1/(o-2),h=-c,u=1+c,d=[h,h,u,h,u,u,h,h,u,u,h,u],f=6,m=6,v=3,g=2,p=1,x=new Float32Array(v*m*f),y=new Float32Array(g*m*f),_=new Float32Array(p*m*f);for(let E=0;E<f;E++){const A=E%3*2/3-1,C=E>2?0:-1,b=[A,C,0,A+2/3,C,0,A+2/3,C+1,0,A,C,0,A+2/3,C+1,0,A,C+1,0];x.set(b,v*m*E),y.set(d,g*m*E);const M=[E,E,E,E,E,E];_.set(M,p*m*E)}const I=new ye;I.setAttribute("position",new ge(x,v)),I.setAttribute("uv",new ge(y,g)),I.setAttribute("faceIndex",new ge(_,p)),t.push(I),i>es&&i--}return{lodPlanes:t,sizeLods:e,sigmas:n}}function _c(r,t,e){const n=new fn(r,t,e);return n.texture.mapping=ia,n.texture.name="PMREM.cubeUv",n.scissorTest=!0,n}function Ar(r,t,e,n,i){r.viewport.set(t,e,n,i),r.scissor.set(t,e,n,i)}function ug(r,t,e){const n=new Float32Array(Ii),i=new P(0,1,0);return new Te({name:"SphericalGaussianBlur",defines:{n:Ii,CUBEUV_TEXEL_WIDTH:1/t,CUBEUV_TEXEL_HEIGHT:1/e,CUBEUV_MAX_MIP:`${r}.0`},uniforms:{envMap:{value:null},samples:{value:1},weights:{value:n},latitudinal:{value:!1},dTheta:{value:0},mipInt:{value:0},poleAxis:{value:i}},vertexShader:fl(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;
			uniform int samples;
			uniform float weights[ n ];
			uniform bool latitudinal;
			uniform float dTheta;
			uniform float mipInt;
			uniform vec3 poleAxis;

			#define ENVMAP_TYPE_CUBE_UV
			#include <cube_uv_reflection_fragment>

			vec3 getSample( float theta, vec3 axis ) {

				float cosTheta = cos( theta );
				// Rodrigues' axis-angle rotation
				vec3 sampleDirection = vOutputDirection * cosTheta
					+ cross( axis, vOutputDirection ) * sin( theta )
					+ axis * dot( axis, vOutputDirection ) * ( 1.0 - cosTheta );

				return bilinearCubeUV( envMap, sampleDirection, mipInt );

			}

			void main() {

				vec3 axis = latitudinal ? poleAxis : cross( poleAxis, vOutputDirection );

				if ( all( equal( axis, vec3( 0.0 ) ) ) ) {

					axis = vec3( vOutputDirection.z, 0.0, - vOutputDirection.x );

				}

				axis = normalize( axis );

				gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 );
				gl_FragColor.rgb += weights[ 0 ] * getSample( 0.0, axis );

				for ( int i = 1; i < n; i++ ) {

					if ( i >= samples ) {

						break;

					}

					float theta = dTheta * float( i );
					gl_FragColor.rgb += weights[ i ] * getSample( -1.0 * theta, axis );
					gl_FragColor.rgb += weights[ i ] * getSample( theta, axis );

				}

			}
		`,blending:$n,depthTest:!1,depthWrite:!1})}function xc(){return new Te({name:"EquirectangularToCubeUV",uniforms:{envMap:{value:null}},vertexShader:fl(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;

			#include <common>

			void main() {

				vec3 outputDirection = normalize( vOutputDirection );
				vec2 uv = equirectUv( outputDirection );

				gl_FragColor = vec4( texture2D ( envMap, uv ).rgb, 1.0 );

			}
		`,blending:$n,depthTest:!1,depthWrite:!1})}function yc(){return new Te({name:"CubemapToCubeUV",uniforms:{envMap:{value:null},flipEnvMap:{value:-1}},vertexShader:fl(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			uniform float flipEnvMap;

			varying vec3 vOutputDirection;

			uniform samplerCube envMap;

			void main() {

				gl_FragColor = textureCube( envMap, vec3( flipEnvMap * vOutputDirection.x, vOutputDirection.yz ) );

			}
		`,blending:$n,depthTest:!1,depthWrite:!1})}function fl(){return`

		precision mediump float;
		precision mediump int;

		attribute float faceIndex;

		varying vec3 vOutputDirection;

		// RH coordinate system; PMREM face-indexing convention
		vec3 getDirection( vec2 uv, float face ) {

			uv = 2.0 * uv - 1.0;

			vec3 direction = vec3( uv, 1.0 );

			if ( face == 0.0 ) {

				direction = direction.zyx; // ( 1, v, u ) pos x

			} else if ( face == 1.0 ) {

				direction = direction.xzy;
				direction.xz *= -1.0; // ( -u, 1, -v ) pos y

			} else if ( face == 2.0 ) {

				direction.x *= -1.0; // ( -u, v, 1 ) pos z

			} else if ( face == 3.0 ) {

				direction = direction.zyx;
				direction.xz *= -1.0; // ( -1, v, -u ) neg x

			} else if ( face == 4.0 ) {

				direction = direction.xzy;
				direction.xy *= -1.0; // ( -u, -1, v ) neg y

			} else if ( face == 5.0 ) {

				direction.z *= -1.0; // ( u, v, -1 ) neg z

			}

			return direction;

		}

		void main() {

			vOutputDirection = getDirection( uv, faceIndex );
			gl_Position = vec4( position, 1.0 );

		}
	`}function dg(r){let t=new WeakMap,e=null;function n(o){if(o&&o.isTexture){const l=o.mapping,c=l===uo||l===fo,h=l===os||l===ls;if(c||h){let u=t.get(o);const d=u!==void 0?u.texture.pmremVersion:0;if(o.isRenderTargetTexture&&o.pmremVersion!==d)return e===null&&(e=new vc(r)),u=c?e.fromEquirectangular(o,u):e.fromCubemap(o,u),u.texture.pmremVersion=o.pmremVersion,t.set(o,u),u.texture;if(u!==void 0)return u.texture;{const f=o.image;return c&&f&&f.height>0||h&&f&&i(f)?(e===null&&(e=new vc(r)),u=c?e.fromEquirectangular(o):e.fromCubemap(o),u.texture.pmremVersion=o.pmremVersion,t.set(o,u),o.addEventListener("dispose",s),u.texture):null}}}return o}function i(o){let l=0;const c=6;for(let h=0;h<c;h++)o[h]!==void 0&&l++;return l===c}function s(o){const l=o.target;l.removeEventListener("dispose",s);const c=t.get(l);c!==void 0&&(t.delete(l),c.dispose())}function a(){t=new WeakMap,e!==null&&(e.dispose(),e=null)}return{get:n,dispose:a}}function fg(r){const t={};function e(n){if(t[n]!==void 0)return t[n];let i;switch(n){case"WEBGL_depth_texture":i=r.getExtension("WEBGL_depth_texture")||r.getExtension("MOZ_WEBGL_depth_texture")||r.getExtension("WEBKIT_WEBGL_depth_texture");break;case"EXT_texture_filter_anisotropic":i=r.getExtension("EXT_texture_filter_anisotropic")||r.getExtension("MOZ_EXT_texture_filter_anisotropic")||r.getExtension("WEBKIT_EXT_texture_filter_anisotropic");break;case"WEBGL_compressed_texture_s3tc":i=r.getExtension("WEBGL_compressed_texture_s3tc")||r.getExtension("MOZ_WEBGL_compressed_texture_s3tc")||r.getExtension("WEBKIT_WEBGL_compressed_texture_s3tc");break;case"WEBGL_compressed_texture_pvrtc":i=r.getExtension("WEBGL_compressed_texture_pvrtc")||r.getExtension("WEBKIT_WEBGL_compressed_texture_pvrtc");break;default:i=r.getExtension(n)}return t[n]=i,i}return{has:function(n){return e(n)!==null},init:function(){e("EXT_color_buffer_float"),e("WEBGL_clip_cull_distance"),e("OES_texture_float_linear"),e("EXT_color_buffer_half_float"),e("WEBGL_multisampled_render_to_texture"),e("WEBGL_render_shared_exponent")},get:function(n){const i=e(n);return i===null&&zs("THREE.WebGLRenderer: "+n+" extension not supported."),i}}}function pg(r,t,e,n){const i={},s=new WeakMap;function a(u){const d=u.target;d.index!==null&&t.remove(d.index);for(const m in d.attributes)t.remove(d.attributes[m]);for(const m in d.morphAttributes){const v=d.morphAttributes[m];for(let g=0,p=v.length;g<p;g++)t.remove(v[g])}d.removeEventListener("dispose",a),delete i[d.id];const f=s.get(d);f&&(t.remove(f),s.delete(d)),n.releaseStatesOfGeometry(d),d.isInstancedBufferGeometry===!0&&delete d._maxInstanceCount,e.memory.geometries--}function o(u,d){return i[d.id]===!0||(d.addEventListener("dispose",a),i[d.id]=!0,e.memory.geometries++),d}function l(u){const d=u.attributes;for(const m in d)t.update(d[m],r.ARRAY_BUFFER);const f=u.morphAttributes;for(const m in f){const v=f[m];for(let g=0,p=v.length;g<p;g++)t.update(v[g],r.ARRAY_BUFFER)}}function c(u){const d=[],f=u.index,m=u.attributes.position;let v=0;if(f!==null){const x=f.array;v=f.version;for(let y=0,_=x.length;y<_;y+=3){const I=x[y+0],E=x[y+1],A=x[y+2];d.push(I,E,E,A,A,I)}}else if(m!==void 0){const x=m.array;v=m.version;for(let y=0,_=x.length/3-1;y<_;y+=3){const I=y+0,E=y+1,A=y+2;d.push(I,E,E,A,A,I)}}else return;const g=new(Zh(d)?iu:nu)(d,1);g.version=v;const p=s.get(u);p&&t.remove(p),s.set(u,g)}function h(u){const d=s.get(u);if(d){const f=u.index;f!==null&&d.version<f.version&&c(u)}else c(u);return s.get(u)}return{get:o,update:l,getWireframeAttribute:h}}function mg(r,t,e){let n;function i(d){n=d}let s,a;function o(d){s=d.type,a=d.bytesPerElement}function l(d,f){r.drawElements(n,f,s,d*a),e.update(f,n,1)}function c(d,f,m){m!==0&&(r.drawElementsInstanced(n,f,s,d*a,m),e.update(f,n,m))}function h(d,f,m){if(m===0)return;t.get("WEBGL_multi_draw").multiDrawElementsWEBGL(n,f,0,s,d,0,m);let g=0;for(let p=0;p<m;p++)g+=f[p];e.update(g,n,1)}function u(d,f,m,v){if(m===0)return;const g=t.get("WEBGL_multi_draw");if(g===null)for(let p=0;p<d.length;p++)c(d[p]/a,f[p],v[p]);else{g.multiDrawElementsInstancedWEBGL(n,f,0,s,d,0,v,0,m);let p=0;for(let x=0;x<m;x++)p+=f[x]*v[x];e.update(p,n,1)}}this.setMode=i,this.setIndex=o,this.render=l,this.renderInstances=c,this.renderMultiDraw=h,this.renderMultiDrawInstances=u}function gg(r){const t={geometries:0,textures:0},e={frame:0,calls:0,triangles:0,points:0,lines:0};function n(s,a,o){switch(e.calls++,a){case r.TRIANGLES:e.triangles+=o*(s/3);break;case r.LINES:e.lines+=o*(s/2);break;case r.LINE_STRIP:e.lines+=o*(s-1);break;case r.LINE_LOOP:e.lines+=o*s;break;case r.POINTS:e.points+=o*s;break;default:console.error("THREE.WebGLInfo: Unknown draw mode:",a);break}}function i(){e.calls=0,e.triangles=0,e.points=0,e.lines=0}return{memory:t,render:e,programs:null,autoReset:!0,reset:i,update:n}}function vg(r,t,e){const n=new WeakMap,i=new Qt;function s(a,o,l){const c=a.morphTargetInfluences,h=o.morphAttributes.position||o.morphAttributes.normal||o.morphAttributes.color,u=h!==void 0?h.length:0;let d=n.get(o);if(d===void 0||d.count!==u){let b=function(){A.dispose(),n.delete(o),o.removeEventListener("dispose",b)};d!==void 0&&d.texture.dispose();const f=o.morphAttributes.position!==void 0,m=o.morphAttributes.normal!==void 0,v=o.morphAttributes.color!==void 0,g=o.morphAttributes.position||[],p=o.morphAttributes.normal||[],x=o.morphAttributes.color||[];let y=0;f===!0&&(y=1),m===!0&&(y=2),v===!0&&(y=3);let _=o.attributes.position.count*y,I=1;_>t.maxTextureSize&&(I=Math.ceil(_/t.maxTextureSize),_=t.maxTextureSize);const E=new Float32Array(_*I*4*u),A=new Qh(E,_,I,u);A.type=Sn,A.needsUpdate=!0;const C=y*4;for(let M=0;M<u;M++){const L=g[M],z=p[M],R=x[M],B=_*I*4*M;for(let j=0;j<L.count;j++){const X=j*C;f===!0&&(i.fromBufferAttribute(L,j),E[B+X+0]=i.x,E[B+X+1]=i.y,E[B+X+2]=i.z,E[B+X+3]=0),m===!0&&(i.fromBufferAttribute(z,j),E[B+X+4]=i.x,E[B+X+5]=i.y,E[B+X+6]=i.z,E[B+X+7]=0),v===!0&&(i.fromBufferAttribute(R,j),E[B+X+8]=i.x,E[B+X+9]=i.y,E[B+X+10]=i.z,E[B+X+11]=R.itemSize===4?i.w:1)}}d={count:u,texture:A,size:new nt(_,I)},n.set(o,d),o.addEventListener("dispose",b)}if(a.isInstancedMesh===!0&&a.morphTexture!==null)l.getUniforms().setValue(r,"morphTexture",a.morphTexture,e);else{let f=0;for(let v=0;v<c.length;v++)f+=c[v];const m=o.morphTargetsRelative?1:1-f;l.getUniforms().setValue(r,"morphTargetBaseInfluence",m),l.getUniforms().setValue(r,"morphTargetInfluences",c)}l.getUniforms().setValue(r,"morphTargetsTexture",d.texture,e),l.getUniforms().setValue(r,"morphTargetsTextureSize",d.size)}return{update:s}}function _g(r,t,e,n){let i=new WeakMap;function s(l){const c=n.render.frame,h=l.geometry,u=t.get(l,h);if(i.get(u)!==c&&(t.update(u),i.set(u,c)),l.isInstancedMesh&&(l.hasEventListener("dispose",o)===!1&&l.addEventListener("dispose",o),i.get(l)!==c&&(e.update(l.instanceMatrix,r.ARRAY_BUFFER),l.instanceColor!==null&&e.update(l.instanceColor,r.ARRAY_BUFFER),i.set(l,c))),l.isSkinnedMesh){const d=l.skeleton;i.get(d)!==c&&(d.update(),i.set(d,c))}return u}function a(){i=new WeakMap}function o(l){const c=l.target;c.removeEventListener("dispose",o),e.remove(c.instanceMatrix),c.instanceColor!==null&&e.remove(c.instanceColor)}return{update:s,dispose:a}}class lu extends Ce{constructor(t,e,n,i,s,a,o,l,c,h=is){if(h!==is&&h!==hs)throw new Error("DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat");n===void 0&&h===is&&(n=Ui),n===void 0&&h===hs&&(n=cs),super(null,i,s,a,o,l,h,n,c),this.isDepthTexture=!0,this.image={width:t,height:e},this.magFilter=o!==void 0?o:Xe,this.minFilter=l!==void 0?l:Xe,this.flipY=!1,this.generateMipmaps=!1,this.compareFunction=null}copy(t){return super.copy(t),this.compareFunction=t.compareFunction,this}toJSON(t){const e=super.toJSON(t);return this.compareFunction!==null&&(e.compareFunction=this.compareFunction),e}}const cu=new Ce,Mc=new lu(1,1),hu=new Qh,uu=new rf,du=new au,bc=[],Sc=[],wc=new Float32Array(16),Tc=new Float32Array(9),Ec=new Float32Array(4);function xs(r,t,e){const n=r[0];if(n<=0||n>0)return r;const i=t*e;let s=bc[i];if(s===void 0&&(s=new Float32Array(i),bc[i]=s),t!==0){n.toArray(s,0);for(let a=1,o=0;a!==t;++a)o+=e,r[a].toArray(s,o)}return s}function Pe(r,t){if(r.length!==t.length)return!1;for(let e=0,n=r.length;e<n;e++)if(r[e]!==t[e])return!1;return!0}function Le(r,t){for(let e=0,n=t.length;e<n;e++)r[e]=t[e]}function oa(r,t){let e=Sc[t];e===void 0&&(e=new Int32Array(t),Sc[t]=e);for(let n=0;n!==t;++n)e[n]=r.allocateTextureUnit();return e}function xg(r,t){const e=this.cache;e[0]!==t&&(r.uniform1f(this.addr,t),e[0]=t)}function yg(r,t){const e=this.cache;if(t.x!==void 0)(e[0]!==t.x||e[1]!==t.y)&&(r.uniform2f(this.addr,t.x,t.y),e[0]=t.x,e[1]=t.y);else{if(Pe(e,t))return;r.uniform2fv(this.addr,t),Le(e,t)}}function Mg(r,t){const e=this.cache;if(t.x!==void 0)(e[0]!==t.x||e[1]!==t.y||e[2]!==t.z)&&(r.uniform3f(this.addr,t.x,t.y,t.z),e[0]=t.x,e[1]=t.y,e[2]=t.z);else if(t.r!==void 0)(e[0]!==t.r||e[1]!==t.g||e[2]!==t.b)&&(r.uniform3f(this.addr,t.r,t.g,t.b),e[0]=t.r,e[1]=t.g,e[2]=t.b);else{if(Pe(e,t))return;r.uniform3fv(this.addr,t),Le(e,t)}}function bg(r,t){const e=this.cache;if(t.x!==void 0)(e[0]!==t.x||e[1]!==t.y||e[2]!==t.z||e[3]!==t.w)&&(r.uniform4f(this.addr,t.x,t.y,t.z,t.w),e[0]=t.x,e[1]=t.y,e[2]=t.z,e[3]=t.w);else{if(Pe(e,t))return;r.uniform4fv(this.addr,t),Le(e,t)}}function Sg(r,t){const e=this.cache,n=t.elements;if(n===void 0){if(Pe(e,t))return;r.uniformMatrix2fv(this.addr,!1,t),Le(e,t)}else{if(Pe(e,n))return;Ec.set(n),r.uniformMatrix2fv(this.addr,!1,Ec),Le(e,n)}}function wg(r,t){const e=this.cache,n=t.elements;if(n===void 0){if(Pe(e,t))return;r.uniformMatrix3fv(this.addr,!1,t),Le(e,t)}else{if(Pe(e,n))return;Tc.set(n),r.uniformMatrix3fv(this.addr,!1,Tc),Le(e,n)}}function Tg(r,t){const e=this.cache,n=t.elements;if(n===void 0){if(Pe(e,t))return;r.uniformMatrix4fv(this.addr,!1,t),Le(e,t)}else{if(Pe(e,n))return;wc.set(n),r.uniformMatrix4fv(this.addr,!1,wc),Le(e,n)}}function Eg(r,t){const e=this.cache;e[0]!==t&&(r.uniform1i(this.addr,t),e[0]=t)}function Ag(r,t){const e=this.cache;if(t.x!==void 0)(e[0]!==t.x||e[1]!==t.y)&&(r.uniform2i(this.addr,t.x,t.y),e[0]=t.x,e[1]=t.y);else{if(Pe(e,t))return;r.uniform2iv(this.addr,t),Le(e,t)}}function Rg(r,t){const e=this.cache;if(t.x!==void 0)(e[0]!==t.x||e[1]!==t.y||e[2]!==t.z)&&(r.uniform3i(this.addr,t.x,t.y,t.z),e[0]=t.x,e[1]=t.y,e[2]=t.z);else{if(Pe(e,t))return;r.uniform3iv(this.addr,t),Le(e,t)}}function Cg(r,t){const e=this.cache;if(t.x!==void 0)(e[0]!==t.x||e[1]!==t.y||e[2]!==t.z||e[3]!==t.w)&&(r.uniform4i(this.addr,t.x,t.y,t.z,t.w),e[0]=t.x,e[1]=t.y,e[2]=t.z,e[3]=t.w);else{if(Pe(e,t))return;r.uniform4iv(this.addr,t),Le(e,t)}}function Pg(r,t){const e=this.cache;e[0]!==t&&(r.uniform1ui(this.addr,t),e[0]=t)}function Lg(r,t){const e=this.cache;if(t.x!==void 0)(e[0]!==t.x||e[1]!==t.y)&&(r.uniform2ui(this.addr,t.x,t.y),e[0]=t.x,e[1]=t.y);else{if(Pe(e,t))return;r.uniform2uiv(this.addr,t),Le(e,t)}}function Ig(r,t){const e=this.cache;if(t.x!==void 0)(e[0]!==t.x||e[1]!==t.y||e[2]!==t.z)&&(r.uniform3ui(this.addr,t.x,t.y,t.z),e[0]=t.x,e[1]=t.y,e[2]=t.z);else{if(Pe(e,t))return;r.uniform3uiv(this.addr,t),Le(e,t)}}function Dg(r,t){const e=this.cache;if(t.x!==void 0)(e[0]!==t.x||e[1]!==t.y||e[2]!==t.z||e[3]!==t.w)&&(r.uniform4ui(this.addr,t.x,t.y,t.z,t.w),e[0]=t.x,e[1]=t.y,e[2]=t.z,e[3]=t.w);else{if(Pe(e,t))return;r.uniform4uiv(this.addr,t),Le(e,t)}}function Ng(r,t,e){const n=this.cache,i=e.allocateTextureUnit();n[0]!==i&&(r.uniform1i(this.addr,i),n[0]=i);let s;this.type===r.SAMPLER_2D_SHADOW?(Mc.compareFunction=$h,s=Mc):s=cu,e.setTexture2D(t||s,i)}function Ug(r,t,e){const n=this.cache,i=e.allocateTextureUnit();n[0]!==i&&(r.uniform1i(this.addr,i),n[0]=i),e.setTexture3D(t||uu,i)}function Fg(r,t,e){const n=this.cache,i=e.allocateTextureUnit();n[0]!==i&&(r.uniform1i(this.addr,i),n[0]=i),e.setTextureCube(t||du,i)}function Og(r,t,e){const n=this.cache,i=e.allocateTextureUnit();n[0]!==i&&(r.uniform1i(this.addr,i),n[0]=i),e.setTexture2DArray(t||hu,i)}function kg(r){switch(r){case 5126:return xg;case 35664:return yg;case 35665:return Mg;case 35666:return bg;case 35674:return Sg;case 35675:return wg;case 35676:return Tg;case 5124:case 35670:return Eg;case 35667:case 35671:return Ag;case 35668:case 35672:return Rg;case 35669:case 35673:return Cg;case 5125:return Pg;case 36294:return Lg;case 36295:return Ig;case 36296:return Dg;case 35678:case 36198:case 36298:case 36306:case 35682:return Ng;case 35679:case 36299:case 36307:return Ug;case 35680:case 36300:case 36308:case 36293:return Fg;case 36289:case 36303:case 36311:case 36292:return Og}}function Bg(r,t){r.uniform1fv(this.addr,t)}function zg(r,t){const e=xs(t,this.size,2);r.uniform2fv(this.addr,e)}function Hg(r,t){const e=xs(t,this.size,3);r.uniform3fv(this.addr,e)}function Vg(r,t){const e=xs(t,this.size,4);r.uniform4fv(this.addr,e)}function Gg(r,t){const e=xs(t,this.size,4);r.uniformMatrix2fv(this.addr,!1,e)}function Wg(r,t){const e=xs(t,this.size,9);r.uniformMatrix3fv(this.addr,!1,e)}function Xg(r,t){const e=xs(t,this.size,16);r.uniformMatrix4fv(this.addr,!1,e)}function qg(r,t){r.uniform1iv(this.addr,t)}function Yg(r,t){r.uniform2iv(this.addr,t)}function Kg(r,t){r.uniform3iv(this.addr,t)}function $g(r,t){r.uniform4iv(this.addr,t)}function jg(r,t){r.uniform1uiv(this.addr,t)}function Zg(r,t){r.uniform2uiv(this.addr,t)}function Jg(r,t){r.uniform3uiv(this.addr,t)}function Qg(r,t){r.uniform4uiv(this.addr,t)}function t0(r,t,e){const n=this.cache,i=t.length,s=oa(e,i);Pe(n,s)||(r.uniform1iv(this.addr,s),Le(n,s));for(let a=0;a!==i;++a)e.setTexture2D(t[a]||cu,s[a])}function e0(r,t,e){const n=this.cache,i=t.length,s=oa(e,i);Pe(n,s)||(r.uniform1iv(this.addr,s),Le(n,s));for(let a=0;a!==i;++a)e.setTexture3D(t[a]||uu,s[a])}function n0(r,t,e){const n=this.cache,i=t.length,s=oa(e,i);Pe(n,s)||(r.uniform1iv(this.addr,s),Le(n,s));for(let a=0;a!==i;++a)e.setTextureCube(t[a]||du,s[a])}function i0(r,t,e){const n=this.cache,i=t.length,s=oa(e,i);Pe(n,s)||(r.uniform1iv(this.addr,s),Le(n,s));for(let a=0;a!==i;++a)e.setTexture2DArray(t[a]||hu,s[a])}function s0(r){switch(r){case 5126:return Bg;case 35664:return zg;case 35665:return Hg;case 35666:return Vg;case 35674:return Gg;case 35675:return Wg;case 35676:return Xg;case 5124:case 35670:return qg;case 35667:case 35671:return Yg;case 35668:case 35672:return Kg;case 35669:case 35673:return $g;case 5125:return jg;case 36294:return Zg;case 36295:return Jg;case 36296:return Qg;case 35678:case 36198:case 36298:case 36306:case 35682:return t0;case 35679:case 36299:case 36307:return e0;case 35680:case 36300:case 36308:case 36293:return n0;case 36289:case 36303:case 36311:case 36292:return i0}}class r0{constructor(t,e,n){this.id=t,this.addr=n,this.cache=[],this.type=e.type,this.setValue=kg(e.type)}}class a0{constructor(t,e,n){this.id=t,this.addr=n,this.cache=[],this.type=e.type,this.size=e.size,this.setValue=s0(e.type)}}class o0{constructor(t){this.id=t,this.seq=[],this.map={}}setValue(t,e,n){const i=this.seq;for(let s=0,a=i.length;s!==a;++s){const o=i[s];o.setValue(t,e[o.id],n)}}}const Ba=/(\w+)(\])?(\[|\.)?/g;function Ac(r,t){r.seq.push(t),r.map[t.id]=t}function l0(r,t,e){const n=r.name,i=n.length;for(Ba.lastIndex=0;;){const s=Ba.exec(n),a=Ba.lastIndex;let o=s[1];const l=s[2]==="]",c=s[3];if(l&&(o=o|0),c===void 0||c==="["&&a+2===i){Ac(e,c===void 0?new r0(o,r,t):new a0(o,r,t));break}else{let u=e.map[o];u===void 0&&(u=new o0(o),Ac(e,u)),e=u}}}class Xr{constructor(t,e){this.seq=[],this.map={};const n=t.getProgramParameter(e,t.ACTIVE_UNIFORMS);for(let i=0;i<n;++i){const s=t.getActiveUniform(e,i),a=t.getUniformLocation(e,s.name);l0(s,a,this)}}setValue(t,e,n,i){const s=this.map[e];s!==void 0&&s.setValue(t,n,i)}setOptional(t,e,n){const i=e[n];i!==void 0&&this.setValue(t,n,i)}static upload(t,e,n,i){for(let s=0,a=e.length;s!==a;++s){const o=e[s],l=n[o.id];l.needsUpdate!==!1&&o.setValue(t,l.value,i)}}static seqWithValue(t,e){const n=[];for(let i=0,s=t.length;i!==s;++i){const a=t[i];a.id in e&&n.push(a)}return n}}function Rc(r,t,e){const n=r.createShader(t);return r.shaderSource(n,e),r.compileShader(n),n}const c0=37297;let h0=0;function u0(r,t){const e=r.split(`
`),n=[],i=Math.max(t-6,0),s=Math.min(t+6,e.length);for(let a=i;a<s;a++){const o=a+1;n.push(`${o===t?">":" "} ${o}: ${e[a]}`)}return n.join(`
`)}const Cc=new Ut;function d0(r){Ht._getMatrix(Cc,Ht.workingColorSpace,r);const t=`mat3( ${Cc.elements.map(e=>e.toFixed(4))} )`;switch(Ht.getTransfer(r)){case sa:return[t,"LinearTransferOETF"];case se:return[t,"sRGBTransferOETF"];default:return console.warn("THREE.WebGLProgram: Unsupported color space: ",r),[t,"LinearTransferOETF"]}}function Pc(r,t,e){const n=r.getShaderParameter(t,r.COMPILE_STATUS),i=r.getShaderInfoLog(t).trim();if(n&&i==="")return"";const s=/ERROR: 0:(\d+)/.exec(i);if(s){const a=parseInt(s[1]);return e.toUpperCase()+`

`+i+`

`+u0(r.getShaderSource(t),a)}else return i}function f0(r,t){const e=d0(t);return[`vec4 ${r}( vec4 value ) {`,`	return ${e[1]}( vec4( value.rgb * ${e[0]}, value.a ) );`,"}"].join(`
`)}function p0(r,t){let e;switch(t){case Ih:e="Linear";break;case Dh:e="Reinhard";break;case Nh:e="Cineon";break;case nl:e="ACESFilmic";break;case Uh:e="AgX";break;case Fh:e="Neutral";break;case yd:e="Custom";break;default:console.warn("THREE.WebGLProgram: Unsupported toneMapping:",t),e="Linear"}return"vec3 "+r+"( vec3 color ) { return "+e+"ToneMapping( color ); }"}const Rr=new P;function m0(){Ht.getLuminanceCoefficients(Rr);const r=Rr.x.toFixed(4),t=Rr.y.toFixed(4),e=Rr.z.toFixed(4);return["float luminance( const in vec3 rgb ) {",`	const vec3 weights = vec3( ${r}, ${t}, ${e} );`,"	return dot( weights, rgb );","}"].join(`
`)}function g0(r){return[r.extensionClipCullDistance?"#extension GL_ANGLE_clip_cull_distance : require":"",r.extensionMultiDraw?"#extension GL_ANGLE_multi_draw : require":""].filter(Hs).join(`
`)}function v0(r){const t=[];for(const e in r){const n=r[e];n!==!1&&t.push("#define "+e+" "+n)}return t.join(`
`)}function _0(r,t){const e={},n=r.getProgramParameter(t,r.ACTIVE_ATTRIBUTES);for(let i=0;i<n;i++){const s=r.getActiveAttrib(t,i),a=s.name;let o=1;s.type===r.FLOAT_MAT2&&(o=2),s.type===r.FLOAT_MAT3&&(o=3),s.type===r.FLOAT_MAT4&&(o=4),e[a]={type:s.type,location:r.getAttribLocation(t,a),locationSize:o}}return e}function Hs(r){return r!==""}function Lc(r,t){const e=t.numSpotLightShadows+t.numSpotLightMaps-t.numSpotLightShadowsWithMaps;return r.replace(/NUM_DIR_LIGHTS/g,t.numDirLights).replace(/NUM_SPOT_LIGHTS/g,t.numSpotLights).replace(/NUM_SPOT_LIGHT_MAPS/g,t.numSpotLightMaps).replace(/NUM_SPOT_LIGHT_COORDS/g,e).replace(/NUM_RECT_AREA_LIGHTS/g,t.numRectAreaLights).replace(/NUM_POINT_LIGHTS/g,t.numPointLights).replace(/NUM_HEMI_LIGHTS/g,t.numHemiLights).replace(/NUM_DIR_LIGHT_SHADOWS/g,t.numDirLightShadows).replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g,t.numSpotLightShadowsWithMaps).replace(/NUM_SPOT_LIGHT_SHADOWS/g,t.numSpotLightShadows).replace(/NUM_POINT_LIGHT_SHADOWS/g,t.numPointLightShadows)}function Ic(r,t){return r.replace(/NUM_CLIPPING_PLANES/g,t.numClippingPlanes).replace(/UNION_CLIPPING_PLANES/g,t.numClippingPlanes-t.numClipIntersection)}const x0=/^[ \t]*#include +<([\w\d./]+)>/gm;function Vo(r){return r.replace(x0,M0)}const y0=new Map;function M0(r,t){let e=Ot[t];if(e===void 0){const n=y0.get(t);if(n!==void 0)e=Ot[n],console.warn('THREE.WebGLRenderer: Shader chunk "%s" has been deprecated. Use "%s" instead.',t,n);else throw new Error("Can not resolve #include <"+t+">")}return Vo(e)}const b0=/#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end/g;function Dc(r){return r.replace(b0,S0)}function S0(r,t,e,n){let i="";for(let s=parseInt(t);s<parseInt(e);s++)i+=n.replace(/\[\s*i\s*\]/g,"[ "+s+" ]").replace(/UNROLLED_LOOP_INDEX/g,s);return i}function Nc(r){let t=`precision ${r.precision} float;
	precision ${r.precision} int;
	precision ${r.precision} sampler2D;
	precision ${r.precision} samplerCube;
	precision ${r.precision} sampler3D;
	precision ${r.precision} sampler2DArray;
	precision ${r.precision} sampler2DShadow;
	precision ${r.precision} samplerCubeShadow;
	precision ${r.precision} sampler2DArrayShadow;
	precision ${r.precision} isampler2D;
	precision ${r.precision} isampler3D;
	precision ${r.precision} isamplerCube;
	precision ${r.precision} isampler2DArray;
	precision ${r.precision} usampler2D;
	precision ${r.precision} usampler3D;
	precision ${r.precision} usamplerCube;
	precision ${r.precision} usampler2DArray;
	`;return r.precision==="highp"?t+=`
#define HIGH_PRECISION`:r.precision==="mediump"?t+=`
#define MEDIUM_PRECISION`:r.precision==="lowp"&&(t+=`
#define LOW_PRECISION`),t}function w0(r){let t="SHADOWMAP_TYPE_BASIC";return r.shadowMapType===Lh?t="SHADOWMAP_TYPE_PCF":r.shadowMapType===Qu?t="SHADOWMAP_TYPE_PCF_SOFT":r.shadowMapType===Wn&&(t="SHADOWMAP_TYPE_VSM"),t}function T0(r){let t="ENVMAP_TYPE_CUBE";if(r.envMap)switch(r.envMapMode){case os:case ls:t="ENVMAP_TYPE_CUBE";break;case ia:t="ENVMAP_TYPE_CUBE_UV";break}return t}function E0(r){let t="ENVMAP_MODE_REFLECTION";if(r.envMap)switch(r.envMapMode){case ls:t="ENVMAP_MODE_REFRACTION";break}return t}function A0(r){let t="ENVMAP_BLENDING_NONE";if(r.envMap)switch(r.combine){case el:t="ENVMAP_BLENDING_MULTIPLY";break;case _d:t="ENVMAP_BLENDING_MIX";break;case xd:t="ENVMAP_BLENDING_ADD";break}return t}function R0(r){const t=r.envMapCubeUVHeight;if(t===null)return null;const e=Math.log2(t)-2,n=1/t;return{texelWidth:1/(3*Math.max(Math.pow(2,e),7*16)),texelHeight:n,maxMip:e}}function C0(r,t,e,n){const i=r.getContext(),s=e.defines;let a=e.vertexShader,o=e.fragmentShader;const l=w0(e),c=T0(e),h=E0(e),u=A0(e),d=R0(e),f=g0(e),m=v0(s),v=i.createProgram();let g,p,x=e.glslVersion?"#version "+e.glslVersion+`
`:"";e.isRawShaderMaterial?(g=["#define SHADER_TYPE "+e.shaderType,"#define SHADER_NAME "+e.shaderName,m].filter(Hs).join(`
`),g.length>0&&(g+=`
`),p=["#define SHADER_TYPE "+e.shaderType,"#define SHADER_NAME "+e.shaderName,m].filter(Hs).join(`
`),p.length>0&&(p+=`
`)):(g=[Nc(e),"#define SHADER_TYPE "+e.shaderType,"#define SHADER_NAME "+e.shaderName,m,e.extensionClipCullDistance?"#define USE_CLIP_DISTANCE":"",e.batching?"#define USE_BATCHING":"",e.batchingColor?"#define USE_BATCHING_COLOR":"",e.instancing?"#define USE_INSTANCING":"",e.instancingColor?"#define USE_INSTANCING_COLOR":"",e.instancingMorph?"#define USE_INSTANCING_MORPH":"",e.useFog&&e.fog?"#define USE_FOG":"",e.useFog&&e.fogExp2?"#define FOG_EXP2":"",e.map?"#define USE_MAP":"",e.envMap?"#define USE_ENVMAP":"",e.envMap?"#define "+h:"",e.lightMap?"#define USE_LIGHTMAP":"",e.aoMap?"#define USE_AOMAP":"",e.bumpMap?"#define USE_BUMPMAP":"",e.normalMap?"#define USE_NORMALMAP":"",e.normalMapObjectSpace?"#define USE_NORMALMAP_OBJECTSPACE":"",e.normalMapTangentSpace?"#define USE_NORMALMAP_TANGENTSPACE":"",e.displacementMap?"#define USE_DISPLACEMENTMAP":"",e.emissiveMap?"#define USE_EMISSIVEMAP":"",e.anisotropy?"#define USE_ANISOTROPY":"",e.anisotropyMap?"#define USE_ANISOTROPYMAP":"",e.clearcoatMap?"#define USE_CLEARCOATMAP":"",e.clearcoatRoughnessMap?"#define USE_CLEARCOAT_ROUGHNESSMAP":"",e.clearcoatNormalMap?"#define USE_CLEARCOAT_NORMALMAP":"",e.iridescenceMap?"#define USE_IRIDESCENCEMAP":"",e.iridescenceThicknessMap?"#define USE_IRIDESCENCE_THICKNESSMAP":"",e.specularMap?"#define USE_SPECULARMAP":"",e.specularColorMap?"#define USE_SPECULAR_COLORMAP":"",e.specularIntensityMap?"#define USE_SPECULAR_INTENSITYMAP":"",e.roughnessMap?"#define USE_ROUGHNESSMAP":"",e.metalnessMap?"#define USE_METALNESSMAP":"",e.alphaMap?"#define USE_ALPHAMAP":"",e.alphaHash?"#define USE_ALPHAHASH":"",e.transmission?"#define USE_TRANSMISSION":"",e.transmissionMap?"#define USE_TRANSMISSIONMAP":"",e.thicknessMap?"#define USE_THICKNESSMAP":"",e.sheenColorMap?"#define USE_SHEEN_COLORMAP":"",e.sheenRoughnessMap?"#define USE_SHEEN_ROUGHNESSMAP":"",e.mapUv?"#define MAP_UV "+e.mapUv:"",e.alphaMapUv?"#define ALPHAMAP_UV "+e.alphaMapUv:"",e.lightMapUv?"#define LIGHTMAP_UV "+e.lightMapUv:"",e.aoMapUv?"#define AOMAP_UV "+e.aoMapUv:"",e.emissiveMapUv?"#define EMISSIVEMAP_UV "+e.emissiveMapUv:"",e.bumpMapUv?"#define BUMPMAP_UV "+e.bumpMapUv:"",e.normalMapUv?"#define NORMALMAP_UV "+e.normalMapUv:"",e.displacementMapUv?"#define DISPLACEMENTMAP_UV "+e.displacementMapUv:"",e.metalnessMapUv?"#define METALNESSMAP_UV "+e.metalnessMapUv:"",e.roughnessMapUv?"#define ROUGHNESSMAP_UV "+e.roughnessMapUv:"",e.anisotropyMapUv?"#define ANISOTROPYMAP_UV "+e.anisotropyMapUv:"",e.clearcoatMapUv?"#define CLEARCOATMAP_UV "+e.clearcoatMapUv:"",e.clearcoatNormalMapUv?"#define CLEARCOAT_NORMALMAP_UV "+e.clearcoatNormalMapUv:"",e.clearcoatRoughnessMapUv?"#define CLEARCOAT_ROUGHNESSMAP_UV "+e.clearcoatRoughnessMapUv:"",e.iridescenceMapUv?"#define IRIDESCENCEMAP_UV "+e.iridescenceMapUv:"",e.iridescenceThicknessMapUv?"#define IRIDESCENCE_THICKNESSMAP_UV "+e.iridescenceThicknessMapUv:"",e.sheenColorMapUv?"#define SHEEN_COLORMAP_UV "+e.sheenColorMapUv:"",e.sheenRoughnessMapUv?"#define SHEEN_ROUGHNESSMAP_UV "+e.sheenRoughnessMapUv:"",e.specularMapUv?"#define SPECULARMAP_UV "+e.specularMapUv:"",e.specularColorMapUv?"#define SPECULAR_COLORMAP_UV "+e.specularColorMapUv:"",e.specularIntensityMapUv?"#define SPECULAR_INTENSITYMAP_UV "+e.specularIntensityMapUv:"",e.transmissionMapUv?"#define TRANSMISSIONMAP_UV "+e.transmissionMapUv:"",e.thicknessMapUv?"#define THICKNESSMAP_UV "+e.thicknessMapUv:"",e.vertexTangents&&e.flatShading===!1?"#define USE_TANGENT":"",e.vertexColors?"#define USE_COLOR":"",e.vertexAlphas?"#define USE_COLOR_ALPHA":"",e.vertexUv1s?"#define USE_UV1":"",e.vertexUv2s?"#define USE_UV2":"",e.vertexUv3s?"#define USE_UV3":"",e.pointsUvs?"#define USE_POINTS_UV":"",e.flatShading?"#define FLAT_SHADED":"",e.skinning?"#define USE_SKINNING":"",e.morphTargets?"#define USE_MORPHTARGETS":"",e.morphNormals&&e.flatShading===!1?"#define USE_MORPHNORMALS":"",e.morphColors?"#define USE_MORPHCOLORS":"",e.morphTargetsCount>0?"#define MORPHTARGETS_TEXTURE_STRIDE "+e.morphTextureStride:"",e.morphTargetsCount>0?"#define MORPHTARGETS_COUNT "+e.morphTargetsCount:"",e.doubleSided?"#define DOUBLE_SIDED":"",e.flipSided?"#define FLIP_SIDED":"",e.shadowMapEnabled?"#define USE_SHADOWMAP":"",e.shadowMapEnabled?"#define "+l:"",e.sizeAttenuation?"#define USE_SIZEATTENUATION":"",e.numLightProbes>0?"#define USE_LIGHT_PROBES":"",e.logarithmicDepthBuffer?"#define USE_LOGDEPTHBUF":"",e.reverseDepthBuffer?"#define USE_REVERSEDEPTHBUF":"","uniform mat4 modelMatrix;","uniform mat4 modelViewMatrix;","uniform mat4 projectionMatrix;","uniform mat4 viewMatrix;","uniform mat3 normalMatrix;","uniform vec3 cameraPosition;","uniform bool isOrthographic;","#ifdef USE_INSTANCING","	attribute mat4 instanceMatrix;","#endif","#ifdef USE_INSTANCING_COLOR","	attribute vec3 instanceColor;","#endif","#ifdef USE_INSTANCING_MORPH","	uniform sampler2D morphTexture;","#endif","attribute vec3 position;","attribute vec3 normal;","attribute vec2 uv;","#ifdef USE_UV1","	attribute vec2 uv1;","#endif","#ifdef USE_UV2","	attribute vec2 uv2;","#endif","#ifdef USE_UV3","	attribute vec2 uv3;","#endif","#ifdef USE_TANGENT","	attribute vec4 tangent;","#endif","#if defined( USE_COLOR_ALPHA )","	attribute vec4 color;","#elif defined( USE_COLOR )","	attribute vec3 color;","#endif","#ifdef USE_SKINNING","	attribute vec4 skinIndex;","	attribute vec4 skinWeight;","#endif",`
`].filter(Hs).join(`
`),p=[Nc(e),"#define SHADER_TYPE "+e.shaderType,"#define SHADER_NAME "+e.shaderName,m,e.useFog&&e.fog?"#define USE_FOG":"",e.useFog&&e.fogExp2?"#define FOG_EXP2":"",e.alphaToCoverage?"#define ALPHA_TO_COVERAGE":"",e.map?"#define USE_MAP":"",e.matcap?"#define USE_MATCAP":"",e.envMap?"#define USE_ENVMAP":"",e.envMap?"#define "+c:"",e.envMap?"#define "+h:"",e.envMap?"#define "+u:"",d?"#define CUBEUV_TEXEL_WIDTH "+d.texelWidth:"",d?"#define CUBEUV_TEXEL_HEIGHT "+d.texelHeight:"",d?"#define CUBEUV_MAX_MIP "+d.maxMip+".0":"",e.lightMap?"#define USE_LIGHTMAP":"",e.aoMap?"#define USE_AOMAP":"",e.bumpMap?"#define USE_BUMPMAP":"",e.normalMap?"#define USE_NORMALMAP":"",e.normalMapObjectSpace?"#define USE_NORMALMAP_OBJECTSPACE":"",e.normalMapTangentSpace?"#define USE_NORMALMAP_TANGENTSPACE":"",e.emissiveMap?"#define USE_EMISSIVEMAP":"",e.anisotropy?"#define USE_ANISOTROPY":"",e.anisotropyMap?"#define USE_ANISOTROPYMAP":"",e.clearcoat?"#define USE_CLEARCOAT":"",e.clearcoatMap?"#define USE_CLEARCOATMAP":"",e.clearcoatRoughnessMap?"#define USE_CLEARCOAT_ROUGHNESSMAP":"",e.clearcoatNormalMap?"#define USE_CLEARCOAT_NORMALMAP":"",e.dispersion?"#define USE_DISPERSION":"",e.iridescence?"#define USE_IRIDESCENCE":"",e.iridescenceMap?"#define USE_IRIDESCENCEMAP":"",e.iridescenceThicknessMap?"#define USE_IRIDESCENCE_THICKNESSMAP":"",e.specularMap?"#define USE_SPECULARMAP":"",e.specularColorMap?"#define USE_SPECULAR_COLORMAP":"",e.specularIntensityMap?"#define USE_SPECULAR_INTENSITYMAP":"",e.roughnessMap?"#define USE_ROUGHNESSMAP":"",e.metalnessMap?"#define USE_METALNESSMAP":"",e.alphaMap?"#define USE_ALPHAMAP":"",e.alphaTest?"#define USE_ALPHATEST":"",e.alphaHash?"#define USE_ALPHAHASH":"",e.sheen?"#define USE_SHEEN":"",e.sheenColorMap?"#define USE_SHEEN_COLORMAP":"",e.sheenRoughnessMap?"#define USE_SHEEN_ROUGHNESSMAP":"",e.transmission?"#define USE_TRANSMISSION":"",e.transmissionMap?"#define USE_TRANSMISSIONMAP":"",e.thicknessMap?"#define USE_THICKNESSMAP":"",e.vertexTangents&&e.flatShading===!1?"#define USE_TANGENT":"",e.vertexColors||e.instancingColor||e.batchingColor?"#define USE_COLOR":"",e.vertexAlphas?"#define USE_COLOR_ALPHA":"",e.vertexUv1s?"#define USE_UV1":"",e.vertexUv2s?"#define USE_UV2":"",e.vertexUv3s?"#define USE_UV3":"",e.pointsUvs?"#define USE_POINTS_UV":"",e.gradientMap?"#define USE_GRADIENTMAP":"",e.flatShading?"#define FLAT_SHADED":"",e.doubleSided?"#define DOUBLE_SIDED":"",e.flipSided?"#define FLIP_SIDED":"",e.shadowMapEnabled?"#define USE_SHADOWMAP":"",e.shadowMapEnabled?"#define "+l:"",e.premultipliedAlpha?"#define PREMULTIPLIED_ALPHA":"",e.numLightProbes>0?"#define USE_LIGHT_PROBES":"",e.decodeVideoTexture?"#define DECODE_VIDEO_TEXTURE":"",e.decodeVideoTextureEmissive?"#define DECODE_VIDEO_TEXTURE_EMISSIVE":"",e.logarithmicDepthBuffer?"#define USE_LOGDEPTHBUF":"",e.reverseDepthBuffer?"#define USE_REVERSEDEPTHBUF":"","uniform mat4 viewMatrix;","uniform vec3 cameraPosition;","uniform bool isOrthographic;",e.toneMapping!==gi?"#define TONE_MAPPING":"",e.toneMapping!==gi?Ot.tonemapping_pars_fragment:"",e.toneMapping!==gi?p0("toneMapping",e.toneMapping):"",e.dithering?"#define DITHERING":"",e.opaque?"#define OPAQUE":"",Ot.colorspace_pars_fragment,f0("linearToOutputTexel",e.outputColorSpace),m0(),e.useDepthPacking?"#define DEPTH_PACKING "+e.depthPacking:"",`
`].filter(Hs).join(`
`)),a=Vo(a),a=Lc(a,e),a=Ic(a,e),o=Vo(o),o=Lc(o,e),o=Ic(o,e),a=Dc(a),o=Dc(o),e.isRawShaderMaterial!==!0&&(x=`#version 300 es
`,g=[f,"#define attribute in","#define varying out","#define texture2D texture"].join(`
`)+`
`+g,p=["#define varying in",e.glslVersion===ql?"":"layout(location = 0) out highp vec4 pc_fragColor;",e.glslVersion===ql?"":"#define gl_FragColor pc_fragColor","#define gl_FragDepthEXT gl_FragDepth","#define texture2D texture","#define textureCube texture","#define texture2DProj textureProj","#define texture2DLodEXT textureLod","#define texture2DProjLodEXT textureProjLod","#define textureCubeLodEXT textureLod","#define texture2DGradEXT textureGrad","#define texture2DProjGradEXT textureProjGrad","#define textureCubeGradEXT textureGrad"].join(`
`)+`
`+p);const y=x+g+a,_=x+p+o,I=Rc(i,i.VERTEX_SHADER,y),E=Rc(i,i.FRAGMENT_SHADER,_);i.attachShader(v,I),i.attachShader(v,E),e.index0AttributeName!==void 0?i.bindAttribLocation(v,0,e.index0AttributeName):e.morphTargets===!0&&i.bindAttribLocation(v,0,"position"),i.linkProgram(v);function A(L){if(r.debug.checkShaderErrors){const z=i.getProgramInfoLog(v).trim(),R=i.getShaderInfoLog(I).trim(),B=i.getShaderInfoLog(E).trim();let j=!0,X=!0;if(i.getProgramParameter(v,i.LINK_STATUS)===!1)if(j=!1,typeof r.debug.onShaderError=="function")r.debug.onShaderError(i,v,I,E);else{const Q=Pc(i,I,"vertex"),G=Pc(i,E,"fragment");console.error("THREE.WebGLProgram: Shader Error "+i.getError()+" - VALIDATE_STATUS "+i.getProgramParameter(v,i.VALIDATE_STATUS)+`

Material Name: `+L.name+`
Material Type: `+L.type+`

Program Info Log: `+z+`
`+Q+`
`+G)}else z!==""?console.warn("THREE.WebGLProgram: Program Info Log:",z):(R===""||B==="")&&(X=!1);X&&(L.diagnostics={runnable:j,programLog:z,vertexShader:{log:R,prefix:g},fragmentShader:{log:B,prefix:p}})}i.deleteShader(I),i.deleteShader(E),C=new Xr(i,v),b=_0(i,v)}let C;this.getUniforms=function(){return C===void 0&&A(this),C};let b;this.getAttributes=function(){return b===void 0&&A(this),b};let M=e.rendererExtensionParallelShaderCompile===!1;return this.isReady=function(){return M===!1&&(M=i.getProgramParameter(v,c0)),M},this.destroy=function(){n.releaseStatesOfProgram(this),i.deleteProgram(v),this.program=void 0},this.type=e.shaderType,this.name=e.shaderName,this.id=h0++,this.cacheKey=t,this.usedTimes=1,this.program=v,this.vertexShader=I,this.fragmentShader=E,this}let P0=0;class L0{constructor(){this.shaderCache=new Map,this.materialCache=new Map}update(t){const e=t.vertexShader,n=t.fragmentShader,i=this._getShaderStage(e),s=this._getShaderStage(n),a=this._getShaderCacheForMaterial(t);return a.has(i)===!1&&(a.add(i),i.usedTimes++),a.has(s)===!1&&(a.add(s),s.usedTimes++),this}remove(t){const e=this.materialCache.get(t);for(const n of e)n.usedTimes--,n.usedTimes===0&&this.shaderCache.delete(n.code);return this.materialCache.delete(t),this}getVertexShaderID(t){return this._getShaderStage(t.vertexShader).id}getFragmentShaderID(t){return this._getShaderStage(t.fragmentShader).id}dispose(){this.shaderCache.clear(),this.materialCache.clear()}_getShaderCacheForMaterial(t){const e=this.materialCache;let n=e.get(t);return n===void 0&&(n=new Set,e.set(t,n)),n}_getShaderStage(t){const e=this.shaderCache;let n=e.get(t);return n===void 0&&(n=new I0(t),e.set(t,n)),n}}class I0{constructor(t){this.id=P0++,this.code=t,this.usedTimes=0}}function D0(r,t,e,n,i,s,a){const o=new tu,l=new L0,c=new Set,h=[],u=i.logarithmicDepthBuffer,d=i.vertexTextures;let f=i.precision;const m={MeshDepthMaterial:"depth",MeshDistanceMaterial:"distanceRGBA",MeshNormalMaterial:"normal",MeshBasicMaterial:"basic",MeshLambertMaterial:"lambert",MeshPhongMaterial:"phong",MeshToonMaterial:"toon",MeshStandardMaterial:"physical",MeshPhysicalMaterial:"physical",MeshMatcapMaterial:"matcap",LineBasicMaterial:"basic",LineDashedMaterial:"dashed",PointsMaterial:"points",ShadowMaterial:"shadow",SpriteMaterial:"sprite"};function v(b){return c.add(b),b===0?"uv":`uv${b}`}function g(b,M,L,z,R){const B=z.fog,j=R.geometry,X=b.isMeshStandardMaterial?z.environment:null,Q=(b.isMeshStandardMaterial?e:t).get(b.envMap||X),G=Q&&Q.mapping===ia?Q.image.height:null,it=m[b.type];b.precision!==null&&(f=i.getMaxPrecision(b.precision),f!==b.precision&&console.warn("THREE.WebGLProgram.getParameters:",b.precision,"not supported, using",f,"instead."));const lt=j.morphAttributes.position||j.morphAttributes.normal||j.morphAttributes.color,St=lt!==void 0?lt.length:0;let kt=0;j.morphAttributes.position!==void 0&&(kt=1),j.morphAttributes.normal!==void 0&&(kt=2),j.morphAttributes.color!==void 0&&(kt=3);let ce,Y,et,yt;if(it){const ie=Rn[it];ce=ie.vertexShader,Y=ie.fragmentShader}else ce=b.vertexShader,Y=b.fragmentShader,l.update(b),et=l.getVertexShaderID(b),yt=l.getFragmentShaderID(b);const at=r.getRenderTarget(),At=r.state.buffers.depth.getReversed(),Lt=R.isInstancedMesh===!0,Bt=R.isBatchedMesh===!0,ve=!!b.map,Yt=!!b.matcap,Se=!!Q,O=!!b.aoMap,nn=!!b.lightMap,Gt=!!b.bumpMap,Wt=!!b.normalMap,Tt=!!b.displacementMap,fe=!!b.emissiveMap,wt=!!b.metalnessMap,T=!!b.roughnessMap,S=b.anisotropy>0,k=b.clearcoat>0,K=b.dispersion>0,Z=b.iridescence>0,q=b.sheen>0,Mt=b.transmission>0,ot=S&&!!b.anisotropyMap,ft=k&&!!b.clearcoatMap,Kt=k&&!!b.clearcoatNormalMap,J=k&&!!b.clearcoatRoughnessMap,pt=Z&&!!b.iridescenceMap,Et=Z&&!!b.iridescenceThicknessMap,Ct=q&&!!b.sheenColorMap,mt=q&&!!b.sheenRoughnessMap,Xt=!!b.specularMap,Ft=!!b.specularColorMap,ue=!!b.specularIntensityMap,N=Mt&&!!b.transmissionMap,rt=Mt&&!!b.thicknessMap,W=!!b.gradientMap,$=!!b.alphaMap,ut=b.alphaTest>0,ct=!!b.alphaHash,Dt=!!b.extensions;let Me=gi;b.toneMapped&&(at===null||at.isXRRenderTarget===!0)&&(Me=r.toneMapping);const Fe={shaderID:it,shaderType:b.type,shaderName:b.name,vertexShader:ce,fragmentShader:Y,defines:b.defines,customVertexShaderID:et,customFragmentShaderID:yt,isRawShaderMaterial:b.isRawShaderMaterial===!0,glslVersion:b.glslVersion,precision:f,batching:Bt,batchingColor:Bt&&R._colorsTexture!==null,instancing:Lt,instancingColor:Lt&&R.instanceColor!==null,instancingMorph:Lt&&R.morphTexture!==null,supportsVertexTextures:d,outputColorSpace:at===null?r.outputColorSpace:at.isXRRenderTarget===!0?at.texture.colorSpace:qe,alphaToCoverage:!!b.alphaToCoverage,map:ve,matcap:Yt,envMap:Se,envMapMode:Se&&Q.mapping,envMapCubeUVHeight:G,aoMap:O,lightMap:nn,bumpMap:Gt,normalMap:Wt,displacementMap:d&&Tt,emissiveMap:fe,normalMapObjectSpace:Wt&&b.normalMapType===Ed,normalMapTangentSpace:Wt&&b.normalMapType===hl,metalnessMap:wt,roughnessMap:T,anisotropy:S,anisotropyMap:ot,clearcoat:k,clearcoatMap:ft,clearcoatNormalMap:Kt,clearcoatRoughnessMap:J,dispersion:K,iridescence:Z,iridescenceMap:pt,iridescenceThicknessMap:Et,sheen:q,sheenColorMap:Ct,sheenRoughnessMap:mt,specularMap:Xt,specularColorMap:Ft,specularIntensityMap:ue,transmission:Mt,transmissionMap:N,thicknessMap:rt,gradientMap:W,opaque:b.transparent===!1&&b.blending===mi&&b.alphaToCoverage===!1,alphaMap:$,alphaTest:ut,alphaHash:ct,combine:b.combine,mapUv:ve&&v(b.map.channel),aoMapUv:O&&v(b.aoMap.channel),lightMapUv:nn&&v(b.lightMap.channel),bumpMapUv:Gt&&v(b.bumpMap.channel),normalMapUv:Wt&&v(b.normalMap.channel),displacementMapUv:Tt&&v(b.displacementMap.channel),emissiveMapUv:fe&&v(b.emissiveMap.channel),metalnessMapUv:wt&&v(b.metalnessMap.channel),roughnessMapUv:T&&v(b.roughnessMap.channel),anisotropyMapUv:ot&&v(b.anisotropyMap.channel),clearcoatMapUv:ft&&v(b.clearcoatMap.channel),clearcoatNormalMapUv:Kt&&v(b.clearcoatNormalMap.channel),clearcoatRoughnessMapUv:J&&v(b.clearcoatRoughnessMap.channel),iridescenceMapUv:pt&&v(b.iridescenceMap.channel),iridescenceThicknessMapUv:Et&&v(b.iridescenceThicknessMap.channel),sheenColorMapUv:Ct&&v(b.sheenColorMap.channel),sheenRoughnessMapUv:mt&&v(b.sheenRoughnessMap.channel),specularMapUv:Xt&&v(b.specularMap.channel),specularColorMapUv:Ft&&v(b.specularColorMap.channel),specularIntensityMapUv:ue&&v(b.specularIntensityMap.channel),transmissionMapUv:N&&v(b.transmissionMap.channel),thicknessMapUv:rt&&v(b.thicknessMap.channel),alphaMapUv:$&&v(b.alphaMap.channel),vertexTangents:!!j.attributes.tangent&&(Wt||S),vertexColors:b.vertexColors,vertexAlphas:b.vertexColors===!0&&!!j.attributes.color&&j.attributes.color.itemSize===4,pointsUvs:R.isPoints===!0&&!!j.attributes.uv&&(ve||$),fog:!!B,useFog:b.fog===!0,fogExp2:!!B&&B.isFogExp2,flatShading:b.flatShading===!0,sizeAttenuation:b.sizeAttenuation===!0,logarithmicDepthBuffer:u,reverseDepthBuffer:At,skinning:R.isSkinnedMesh===!0,morphTargets:j.morphAttributes.position!==void 0,morphNormals:j.morphAttributes.normal!==void 0,morphColors:j.morphAttributes.color!==void 0,morphTargetsCount:St,morphTextureStride:kt,numDirLights:M.directional.length,numPointLights:M.point.length,numSpotLights:M.spot.length,numSpotLightMaps:M.spotLightMap.length,numRectAreaLights:M.rectArea.length,numHemiLights:M.hemi.length,numDirLightShadows:M.directionalShadowMap.length,numPointLightShadows:M.pointShadowMap.length,numSpotLightShadows:M.spotShadowMap.length,numSpotLightShadowsWithMaps:M.numSpotLightShadowsWithMaps,numLightProbes:M.numLightProbes,numClippingPlanes:a.numPlanes,numClipIntersection:a.numIntersection,dithering:b.dithering,shadowMapEnabled:r.shadowMap.enabled&&L.length>0,shadowMapType:r.shadowMap.type,toneMapping:Me,decodeVideoTexture:ve&&b.map.isVideoTexture===!0&&Ht.getTransfer(b.map.colorSpace)===se,decodeVideoTextureEmissive:fe&&b.emissiveMap.isVideoTexture===!0&&Ht.getTransfer(b.emissiveMap.colorSpace)===se,premultipliedAlpha:b.premultipliedAlpha,doubleSided:b.side===hn,flipSided:b.side===$e,useDepthPacking:b.depthPacking>=0,depthPacking:b.depthPacking||0,index0AttributeName:b.index0AttributeName,extensionClipCullDistance:Dt&&b.extensions.clipCullDistance===!0&&n.has("WEBGL_clip_cull_distance"),extensionMultiDraw:(Dt&&b.extensions.multiDraw===!0||Bt)&&n.has("WEBGL_multi_draw"),rendererExtensionParallelShaderCompile:n.has("KHR_parallel_shader_compile"),customProgramCacheKey:b.customProgramCacheKey()};return Fe.vertexUv1s=c.has(1),Fe.vertexUv2s=c.has(2),Fe.vertexUv3s=c.has(3),c.clear(),Fe}function p(b){const M=[];if(b.shaderID?M.push(b.shaderID):(M.push(b.customVertexShaderID),M.push(b.customFragmentShaderID)),b.defines!==void 0)for(const L in b.defines)M.push(L),M.push(b.defines[L]);return b.isRawShaderMaterial===!1&&(x(M,b),y(M,b),M.push(r.outputColorSpace)),M.push(b.customProgramCacheKey),M.join()}function x(b,M){b.push(M.precision),b.push(M.outputColorSpace),b.push(M.envMapMode),b.push(M.envMapCubeUVHeight),b.push(M.mapUv),b.push(M.alphaMapUv),b.push(M.lightMapUv),b.push(M.aoMapUv),b.push(M.bumpMapUv),b.push(M.normalMapUv),b.push(M.displacementMapUv),b.push(M.emissiveMapUv),b.push(M.metalnessMapUv),b.push(M.roughnessMapUv),b.push(M.anisotropyMapUv),b.push(M.clearcoatMapUv),b.push(M.clearcoatNormalMapUv),b.push(M.clearcoatRoughnessMapUv),b.push(M.iridescenceMapUv),b.push(M.iridescenceThicknessMapUv),b.push(M.sheenColorMapUv),b.push(M.sheenRoughnessMapUv),b.push(M.specularMapUv),b.push(M.specularColorMapUv),b.push(M.specularIntensityMapUv),b.push(M.transmissionMapUv),b.push(M.thicknessMapUv),b.push(M.combine),b.push(M.fogExp2),b.push(M.sizeAttenuation),b.push(M.morphTargetsCount),b.push(M.morphAttributeCount),b.push(M.numDirLights),b.push(M.numPointLights),b.push(M.numSpotLights),b.push(M.numSpotLightMaps),b.push(M.numHemiLights),b.push(M.numRectAreaLights),b.push(M.numDirLightShadows),b.push(M.numPointLightShadows),b.push(M.numSpotLightShadows),b.push(M.numSpotLightShadowsWithMaps),b.push(M.numLightProbes),b.push(M.shadowMapType),b.push(M.toneMapping),b.push(M.numClippingPlanes),b.push(M.numClipIntersection),b.push(M.depthPacking)}function y(b,M){o.disableAll(),M.supportsVertexTextures&&o.enable(0),M.instancing&&o.enable(1),M.instancingColor&&o.enable(2),M.instancingMorph&&o.enable(3),M.matcap&&o.enable(4),M.envMap&&o.enable(5),M.normalMapObjectSpace&&o.enable(6),M.normalMapTangentSpace&&o.enable(7),M.clearcoat&&o.enable(8),M.iridescence&&o.enable(9),M.alphaTest&&o.enable(10),M.vertexColors&&o.enable(11),M.vertexAlphas&&o.enable(12),M.vertexUv1s&&o.enable(13),M.vertexUv2s&&o.enable(14),M.vertexUv3s&&o.enable(15),M.vertexTangents&&o.enable(16),M.anisotropy&&o.enable(17),M.alphaHash&&o.enable(18),M.batching&&o.enable(19),M.dispersion&&o.enable(20),M.batchingColor&&o.enable(21),b.push(o.mask),o.disableAll(),M.fog&&o.enable(0),M.useFog&&o.enable(1),M.flatShading&&o.enable(2),M.logarithmicDepthBuffer&&o.enable(3),M.reverseDepthBuffer&&o.enable(4),M.skinning&&o.enable(5),M.morphTargets&&o.enable(6),M.morphNormals&&o.enable(7),M.morphColors&&o.enable(8),M.premultipliedAlpha&&o.enable(9),M.shadowMapEnabled&&o.enable(10),M.doubleSided&&o.enable(11),M.flipSided&&o.enable(12),M.useDepthPacking&&o.enable(13),M.dithering&&o.enable(14),M.transmission&&o.enable(15),M.sheen&&o.enable(16),M.opaque&&o.enable(17),M.pointsUvs&&o.enable(18),M.decodeVideoTexture&&o.enable(19),M.decodeVideoTextureEmissive&&o.enable(20),M.alphaToCoverage&&o.enable(21),b.push(o.mask)}function _(b){const M=m[b.type];let L;if(M){const z=Rn[M];L=Js.clone(z.uniforms)}else L=b.uniforms;return L}function I(b,M){let L;for(let z=0,R=h.length;z<R;z++){const B=h[z];if(B.cacheKey===M){L=B,++L.usedTimes;break}}return L===void 0&&(L=new C0(r,M,b,s),h.push(L)),L}function E(b){if(--b.usedTimes===0){const M=h.indexOf(b);h[M]=h[h.length-1],h.pop(),b.destroy()}}function A(b){l.remove(b)}function C(){l.dispose()}return{getParameters:g,getProgramCacheKey:p,getUniforms:_,acquireProgram:I,releaseProgram:E,releaseShaderCache:A,programs:h,dispose:C}}function N0(){let r=new WeakMap;function t(a){return r.has(a)}function e(a){let o=r.get(a);return o===void 0&&(o={},r.set(a,o)),o}function n(a){r.delete(a)}function i(a,o,l){r.get(a)[o]=l}function s(){r=new WeakMap}return{has:t,get:e,remove:n,update:i,dispose:s}}function U0(r,t){return r.groupOrder!==t.groupOrder?r.groupOrder-t.groupOrder:r.renderOrder!==t.renderOrder?r.renderOrder-t.renderOrder:r.material.id!==t.material.id?r.material.id-t.material.id:r.z!==t.z?r.z-t.z:r.id-t.id}function Uc(r,t){return r.groupOrder!==t.groupOrder?r.groupOrder-t.groupOrder:r.renderOrder!==t.renderOrder?r.renderOrder-t.renderOrder:r.z!==t.z?t.z-r.z:r.id-t.id}function Fc(){const r=[];let t=0;const e=[],n=[],i=[];function s(){t=0,e.length=0,n.length=0,i.length=0}function a(u,d,f,m,v,g){let p=r[t];return p===void 0?(p={id:u.id,object:u,geometry:d,material:f,groupOrder:m,renderOrder:u.renderOrder,z:v,group:g},r[t]=p):(p.id=u.id,p.object=u,p.geometry=d,p.material=f,p.groupOrder=m,p.renderOrder=u.renderOrder,p.z=v,p.group=g),t++,p}function o(u,d,f,m,v,g){const p=a(u,d,f,m,v,g);f.transmission>0?n.push(p):f.transparent===!0?i.push(p):e.push(p)}function l(u,d,f,m,v,g){const p=a(u,d,f,m,v,g);f.transmission>0?n.unshift(p):f.transparent===!0?i.unshift(p):e.unshift(p)}function c(u,d){e.length>1&&e.sort(u||U0),n.length>1&&n.sort(d||Uc),i.length>1&&i.sort(d||Uc)}function h(){for(let u=t,d=r.length;u<d;u++){const f=r[u];if(f.id===null)break;f.id=null,f.object=null,f.geometry=null,f.material=null,f.group=null}}return{opaque:e,transmissive:n,transparent:i,init:s,push:o,unshift:l,finish:h,sort:c}}function F0(){let r=new WeakMap;function t(n,i){const s=r.get(n);let a;return s===void 0?(a=new Fc,r.set(n,[a])):i>=s.length?(a=new Fc,s.push(a)):a=s[i],a}function e(){r=new WeakMap}return{get:t,dispose:e}}function O0(){const r={};return{get:function(t){if(r[t.id]!==void 0)return r[t.id];let e;switch(t.type){case"DirectionalLight":e={direction:new P,color:new dt};break;case"SpotLight":e={position:new P,direction:new P,color:new dt,distance:0,coneCos:0,penumbraCos:0,decay:0};break;case"PointLight":e={position:new P,color:new dt,distance:0,decay:0};break;case"HemisphereLight":e={direction:new P,skyColor:new dt,groundColor:new dt};break;case"RectAreaLight":e={color:new dt,position:new P,halfWidth:new P,halfHeight:new P};break}return r[t.id]=e,e}}}function k0(){const r={};return{get:function(t){if(r[t.id]!==void 0)return r[t.id];let e;switch(t.type){case"DirectionalLight":e={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new nt};break;case"SpotLight":e={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new nt};break;case"PointLight":e={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new nt,shadowCameraNear:1,shadowCameraFar:1e3};break}return r[t.id]=e,e}}}let B0=0;function z0(r,t){return(t.castShadow?2:0)-(r.castShadow?2:0)+(t.map?1:0)-(r.map?1:0)}function H0(r){const t=new O0,e=k0(),n={version:0,hash:{directionalLength:-1,pointLength:-1,spotLength:-1,rectAreaLength:-1,hemiLength:-1,numDirectionalShadows:-1,numPointShadows:-1,numSpotShadows:-1,numSpotMaps:-1,numLightProbes:-1},ambient:[0,0,0],probe:[],directional:[],directionalShadow:[],directionalShadowMap:[],directionalShadowMatrix:[],spot:[],spotLightMap:[],spotShadow:[],spotShadowMap:[],spotLightMatrix:[],rectArea:[],rectAreaLTC1:null,rectAreaLTC2:null,point:[],pointShadow:[],pointShadowMap:[],pointShadowMatrix:[],hemi:[],numSpotLightShadowsWithMaps:0,numLightProbes:0};for(let c=0;c<9;c++)n.probe.push(new P);const i=new P,s=new It,a=new It;function o(c){let h=0,u=0,d=0;for(let b=0;b<9;b++)n.probe[b].set(0,0,0);let f=0,m=0,v=0,g=0,p=0,x=0,y=0,_=0,I=0,E=0,A=0;c.sort(z0);for(let b=0,M=c.length;b<M;b++){const L=c[b],z=L.color,R=L.intensity,B=L.distance,j=L.shadow&&L.shadow.map?L.shadow.map.texture:null;if(L.isAmbientLight)h+=z.r*R,u+=z.g*R,d+=z.b*R;else if(L.isLightProbe){for(let X=0;X<9;X++)n.probe[X].addScaledVector(L.sh.coefficients[X],R);A++}else if(L.isDirectionalLight){const X=t.get(L);if(X.color.copy(L.color).multiplyScalar(L.intensity),L.castShadow){const Q=L.shadow,G=e.get(L);G.shadowIntensity=Q.intensity,G.shadowBias=Q.bias,G.shadowNormalBias=Q.normalBias,G.shadowRadius=Q.radius,G.shadowMapSize=Q.mapSize,n.directionalShadow[f]=G,n.directionalShadowMap[f]=j,n.directionalShadowMatrix[f]=L.shadow.matrix,x++}n.directional[f]=X,f++}else if(L.isSpotLight){const X=t.get(L);X.position.setFromMatrixPosition(L.matrixWorld),X.color.copy(z).multiplyScalar(R),X.distance=B,X.coneCos=Math.cos(L.angle),X.penumbraCos=Math.cos(L.angle*(1-L.penumbra)),X.decay=L.decay,n.spot[v]=X;const Q=L.shadow;if(L.map&&(n.spotLightMap[I]=L.map,I++,Q.updateMatrices(L),L.castShadow&&E++),n.spotLightMatrix[v]=Q.matrix,L.castShadow){const G=e.get(L);G.shadowIntensity=Q.intensity,G.shadowBias=Q.bias,G.shadowNormalBias=Q.normalBias,G.shadowRadius=Q.radius,G.shadowMapSize=Q.mapSize,n.spotShadow[v]=G,n.spotShadowMap[v]=j,_++}v++}else if(L.isRectAreaLight){const X=t.get(L);X.color.copy(z).multiplyScalar(R),X.halfWidth.set(L.width*.5,0,0),X.halfHeight.set(0,L.height*.5,0),n.rectArea[g]=X,g++}else if(L.isPointLight){const X=t.get(L);if(X.color.copy(L.color).multiplyScalar(L.intensity),X.distance=L.distance,X.decay=L.decay,L.castShadow){const Q=L.shadow,G=e.get(L);G.shadowIntensity=Q.intensity,G.shadowBias=Q.bias,G.shadowNormalBias=Q.normalBias,G.shadowRadius=Q.radius,G.shadowMapSize=Q.mapSize,G.shadowCameraNear=Q.camera.near,G.shadowCameraFar=Q.camera.far,n.pointShadow[m]=G,n.pointShadowMap[m]=j,n.pointShadowMatrix[m]=L.shadow.matrix,y++}n.point[m]=X,m++}else if(L.isHemisphereLight){const X=t.get(L);X.skyColor.copy(L.color).multiplyScalar(R),X.groundColor.copy(L.groundColor).multiplyScalar(R),n.hemi[p]=X,p++}}g>0&&(r.has("OES_texture_float_linear")===!0?(n.rectAreaLTC1=st.LTC_FLOAT_1,n.rectAreaLTC2=st.LTC_FLOAT_2):(n.rectAreaLTC1=st.LTC_HALF_1,n.rectAreaLTC2=st.LTC_HALF_2)),n.ambient[0]=h,n.ambient[1]=u,n.ambient[2]=d;const C=n.hash;(C.directionalLength!==f||C.pointLength!==m||C.spotLength!==v||C.rectAreaLength!==g||C.hemiLength!==p||C.numDirectionalShadows!==x||C.numPointShadows!==y||C.numSpotShadows!==_||C.numSpotMaps!==I||C.numLightProbes!==A)&&(n.directional.length=f,n.spot.length=v,n.rectArea.length=g,n.point.length=m,n.hemi.length=p,n.directionalShadow.length=x,n.directionalShadowMap.length=x,n.pointShadow.length=y,n.pointShadowMap.length=y,n.spotShadow.length=_,n.spotShadowMap.length=_,n.directionalShadowMatrix.length=x,n.pointShadowMatrix.length=y,n.spotLightMatrix.length=_+I-E,n.spotLightMap.length=I,n.numSpotLightShadowsWithMaps=E,n.numLightProbes=A,C.directionalLength=f,C.pointLength=m,C.spotLength=v,C.rectAreaLength=g,C.hemiLength=p,C.numDirectionalShadows=x,C.numPointShadows=y,C.numSpotShadows=_,C.numSpotMaps=I,C.numLightProbes=A,n.version=B0++)}function l(c,h){let u=0,d=0,f=0,m=0,v=0;const g=h.matrixWorldInverse;for(let p=0,x=c.length;p<x;p++){const y=c[p];if(y.isDirectionalLight){const _=n.directional[u];_.direction.setFromMatrixPosition(y.matrixWorld),i.setFromMatrixPosition(y.target.matrixWorld),_.direction.sub(i),_.direction.transformDirection(g),u++}else if(y.isSpotLight){const _=n.spot[f];_.position.setFromMatrixPosition(y.matrixWorld),_.position.applyMatrix4(g),_.direction.setFromMatrixPosition(y.matrixWorld),i.setFromMatrixPosition(y.target.matrixWorld),_.direction.sub(i),_.direction.transformDirection(g),f++}else if(y.isRectAreaLight){const _=n.rectArea[m];_.position.setFromMatrixPosition(y.matrixWorld),_.position.applyMatrix4(g),a.identity(),s.copy(y.matrixWorld),s.premultiply(g),a.extractRotation(s),_.halfWidth.set(y.width*.5,0,0),_.halfHeight.set(0,y.height*.5,0),_.halfWidth.applyMatrix4(a),_.halfHeight.applyMatrix4(a),m++}else if(y.isPointLight){const _=n.point[d];_.position.setFromMatrixPosition(y.matrixWorld),_.position.applyMatrix4(g),d++}else if(y.isHemisphereLight){const _=n.hemi[v];_.direction.setFromMatrixPosition(y.matrixWorld),_.direction.transformDirection(g),v++}}}return{setup:o,setupView:l,state:n}}function Oc(r){const t=new H0(r),e=[],n=[];function i(h){c.camera=h,e.length=0,n.length=0}function s(h){e.push(h)}function a(h){n.push(h)}function o(){t.setup(e)}function l(h){t.setupView(e,h)}const c={lightsArray:e,shadowsArray:n,camera:null,lights:t,transmissionRenderTarget:{}};return{init:i,state:c,setupLights:o,setupLightsView:l,pushLight:s,pushShadow:a}}function V0(r){let t=new WeakMap;function e(i,s=0){const a=t.get(i);let o;return a===void 0?(o=new Oc(r),t.set(i,[o])):s>=a.length?(o=new Oc(r),a.push(o)):o=a[s],o}function n(){t=new WeakMap}return{get:e,dispose:n}}class G0 extends Tn{static get type(){return"MeshDepthMaterial"}constructor(t){super(),this.isMeshDepthMaterial=!0,this.depthPacking=wd,this.map=null,this.alphaMap=null,this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.wireframe=!1,this.wireframeLinewidth=1,this.setValues(t)}copy(t){return super.copy(t),this.depthPacking=t.depthPacking,this.map=t.map,this.alphaMap=t.alphaMap,this.displacementMap=t.displacementMap,this.displacementScale=t.displacementScale,this.displacementBias=t.displacementBias,this.wireframe=t.wireframe,this.wireframeLinewidth=t.wireframeLinewidth,this}}class W0 extends Tn{static get type(){return"MeshDistanceMaterial"}constructor(t){super(),this.isMeshDistanceMaterial=!0,this.map=null,this.alphaMap=null,this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.setValues(t)}copy(t){return super.copy(t),this.map=t.map,this.alphaMap=t.alphaMap,this.displacementMap=t.displacementMap,this.displacementScale=t.displacementScale,this.displacementBias=t.displacementBias,this}}const X0=`void main() {
	gl_Position = vec4( position, 1.0 );
}`,q0=`uniform sampler2D shadow_pass;
uniform vec2 resolution;
uniform float radius;
#include <packing>
void main() {
	const float samples = float( VSM_SAMPLES );
	float mean = 0.0;
	float squared_mean = 0.0;
	float uvStride = samples <= 1.0 ? 0.0 : 2.0 / ( samples - 1.0 );
	float uvStart = samples <= 1.0 ? 0.0 : - 1.0;
	for ( float i = 0.0; i < samples; i ++ ) {
		float uvOffset = uvStart + i * uvStride;
		#ifdef HORIZONTAL_PASS
			vec2 distribution = unpackRGBATo2Half( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( uvOffset, 0.0 ) * radius ) / resolution ) );
			mean += distribution.x;
			squared_mean += distribution.y * distribution.y + distribution.x * distribution.x;
		#else
			float depth = unpackRGBAToDepth( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( 0.0, uvOffset ) * radius ) / resolution ) );
			mean += depth;
			squared_mean += depth * depth;
		#endif
	}
	mean = mean / samples;
	squared_mean = squared_mean / samples;
	float std_dev = sqrt( squared_mean - mean * mean );
	gl_FragColor = pack2HalfToRGBA( vec2( mean, std_dev ) );
}`;function Y0(r,t,e){let n=new dl;const i=new nt,s=new nt,a=new Qt,o=new G0({depthPacking:Td}),l=new W0,c={},h=e.maxTextureSize,u={[Zn]:$e,[$e]:Zn,[hn]:hn},d=new Te({defines:{VSM_SAMPLES:8},uniforms:{shadow_pass:{value:null},resolution:{value:new nt},radius:{value:4}},vertexShader:X0,fragmentShader:q0}),f=d.clone();f.defines.HORIZONTAL_PASS=1;const m=new ye;m.setAttribute("position",new ge(new Float32Array([-1,-1,.5,3,-1,.5,-1,3,.5]),3));const v=new Rt(m,d),g=this;this.enabled=!1,this.autoUpdate=!0,this.needsUpdate=!1,this.type=Lh;let p=this.type;this.render=function(E,A,C){if(g.enabled===!1||g.autoUpdate===!1&&g.needsUpdate===!1||E.length===0)return;const b=r.getRenderTarget(),M=r.getActiveCubeFace(),L=r.getActiveMipmapLevel(),z=r.state;z.setBlending($n),z.buffers.color.setClear(1,1,1,1),z.buffers.depth.setTest(!0),z.setScissorTest(!1);const R=p!==Wn&&this.type===Wn,B=p===Wn&&this.type!==Wn;for(let j=0,X=E.length;j<X;j++){const Q=E[j],G=Q.shadow;if(G===void 0){console.warn("THREE.WebGLShadowMap:",Q,"has no shadow.");continue}if(G.autoUpdate===!1&&G.needsUpdate===!1)continue;i.copy(G.mapSize);const it=G.getFrameExtents();if(i.multiply(it),s.copy(G.mapSize),(i.x>h||i.y>h)&&(i.x>h&&(s.x=Math.floor(h/it.x),i.x=s.x*it.x,G.mapSize.x=s.x),i.y>h&&(s.y=Math.floor(h/it.y),i.y=s.y*it.y,G.mapSize.y=s.y)),G.map===null||R===!0||B===!0){const St=this.type!==Wn?{minFilter:Xe,magFilter:Xe}:{};G.map!==null&&G.map.dispose(),G.map=new fn(i.x,i.y,St),G.map.texture.name=Q.name+".shadowMap",G.camera.updateProjectionMatrix()}r.setRenderTarget(G.map),r.clear();const lt=G.getViewportCount();for(let St=0;St<lt;St++){const kt=G.getViewport(St);a.set(s.x*kt.x,s.y*kt.y,s.x*kt.z,s.y*kt.w),z.viewport(a),G.updateMatrices(Q,St),n=G.getFrustum(),_(A,C,G.camera,Q,this.type)}G.isPointLightShadow!==!0&&this.type===Wn&&x(G,C),G.needsUpdate=!1}p=this.type,g.needsUpdate=!1,r.setRenderTarget(b,M,L)};function x(E,A){const C=t.update(v);d.defines.VSM_SAMPLES!==E.blurSamples&&(d.defines.VSM_SAMPLES=E.blurSamples,f.defines.VSM_SAMPLES=E.blurSamples,d.needsUpdate=!0,f.needsUpdate=!0),E.mapPass===null&&(E.mapPass=new fn(i.x,i.y)),d.uniforms.shadow_pass.value=E.map.texture,d.uniforms.resolution.value=E.mapSize,d.uniforms.radius.value=E.radius,r.setRenderTarget(E.mapPass),r.clear(),r.renderBufferDirect(A,null,C,d,v,null),f.uniforms.shadow_pass.value=E.mapPass.texture,f.uniforms.resolution.value=E.mapSize,f.uniforms.radius.value=E.radius,r.setRenderTarget(E.map),r.clear(),r.renderBufferDirect(A,null,C,f,v,null)}function y(E,A,C,b){let M=null;const L=C.isPointLight===!0?E.customDistanceMaterial:E.customDepthMaterial;if(L!==void 0)M=L;else if(M=C.isPointLight===!0?l:o,r.localClippingEnabled&&A.clipShadows===!0&&Array.isArray(A.clippingPlanes)&&A.clippingPlanes.length!==0||A.displacementMap&&A.displacementScale!==0||A.alphaMap&&A.alphaTest>0||A.map&&A.alphaTest>0){const z=M.uuid,R=A.uuid;let B=c[z];B===void 0&&(B={},c[z]=B);let j=B[R];j===void 0&&(j=M.clone(),B[R]=j,A.addEventListener("dispose",I)),M=j}if(M.visible=A.visible,M.wireframe=A.wireframe,b===Wn?M.side=A.shadowSide!==null?A.shadowSide:A.side:M.side=A.shadowSide!==null?A.shadowSide:u[A.side],M.alphaMap=A.alphaMap,M.alphaTest=A.alphaTest,M.map=A.map,M.clipShadows=A.clipShadows,M.clippingPlanes=A.clippingPlanes,M.clipIntersection=A.clipIntersection,M.displacementMap=A.displacementMap,M.displacementScale=A.displacementScale,M.displacementBias=A.displacementBias,M.wireframeLinewidth=A.wireframeLinewidth,M.linewidth=A.linewidth,C.isPointLight===!0&&M.isMeshDistanceMaterial===!0){const z=r.properties.get(M);z.light=C}return M}function _(E,A,C,b,M){if(E.visible===!1)return;if(E.layers.test(A.layers)&&(E.isMesh||E.isLine||E.isPoints)&&(E.castShadow||E.receiveShadow&&M===Wn)&&(!E.frustumCulled||n.intersectsObject(E))){E.modelViewMatrix.multiplyMatrices(C.matrixWorldInverse,E.matrixWorld);const R=t.update(E),B=E.material;if(Array.isArray(B)){const j=R.groups;for(let X=0,Q=j.length;X<Q;X++){const G=j[X],it=B[G.materialIndex];if(it&&it.visible){const lt=y(E,it,b,M);E.onBeforeShadow(r,E,A,C,R,lt,G),r.renderBufferDirect(C,null,R,lt,E,G),E.onAfterShadow(r,E,A,C,R,lt,G)}}}else if(B.visible){const j=y(E,B,b,M);E.onBeforeShadow(r,E,A,C,R,j,null),r.renderBufferDirect(C,null,R,j,E,null),E.onAfterShadow(r,E,A,C,R,j,null)}}const z=E.children;for(let R=0,B=z.length;R<B;R++)_(z[R],A,C,b,M)}function I(E){E.target.removeEventListener("dispose",I);for(const C in c){const b=c[C],M=E.target.uuid;M in b&&(b[M].dispose(),delete b[M])}}}const K0={[so]:ro,[ao]:co,[oo]:ho,[as]:lo,[ro]:so,[co]:ao,[ho]:oo,[lo]:as};function $0(r,t){function e(){let N=!1;const rt=new Qt;let W=null;const $=new Qt(0,0,0,0);return{setMask:function(ut){W!==ut&&!N&&(r.colorMask(ut,ut,ut,ut),W=ut)},setLocked:function(ut){N=ut},setClear:function(ut,ct,Dt,Me,Fe){Fe===!0&&(ut*=Me,ct*=Me,Dt*=Me),rt.set(ut,ct,Dt,Me),$.equals(rt)===!1&&(r.clearColor(ut,ct,Dt,Me),$.copy(rt))},reset:function(){N=!1,W=null,$.set(-1,0,0,0)}}}function n(){let N=!1,rt=!1,W=null,$=null,ut=null;return{setReversed:function(ct){if(rt!==ct){const Dt=t.get("EXT_clip_control");rt?Dt.clipControlEXT(Dt.LOWER_LEFT_EXT,Dt.ZERO_TO_ONE_EXT):Dt.clipControlEXT(Dt.LOWER_LEFT_EXT,Dt.NEGATIVE_ONE_TO_ONE_EXT);const Me=ut;ut=null,this.setClear(Me)}rt=ct},getReversed:function(){return rt},setTest:function(ct){ct?at(r.DEPTH_TEST):At(r.DEPTH_TEST)},setMask:function(ct){W!==ct&&!N&&(r.depthMask(ct),W=ct)},setFunc:function(ct){if(rt&&(ct=K0[ct]),$!==ct){switch(ct){case so:r.depthFunc(r.NEVER);break;case ro:r.depthFunc(r.ALWAYS);break;case ao:r.depthFunc(r.LESS);break;case as:r.depthFunc(r.LEQUAL);break;case oo:r.depthFunc(r.EQUAL);break;case lo:r.depthFunc(r.GEQUAL);break;case co:r.depthFunc(r.GREATER);break;case ho:r.depthFunc(r.NOTEQUAL);break;default:r.depthFunc(r.LEQUAL)}$=ct}},setLocked:function(ct){N=ct},setClear:function(ct){ut!==ct&&(rt&&(ct=1-ct),r.clearDepth(ct),ut=ct)},reset:function(){N=!1,W=null,$=null,ut=null,rt=!1}}}function i(){let N=!1,rt=null,W=null,$=null,ut=null,ct=null,Dt=null,Me=null,Fe=null;return{setTest:function(ie){N||(ie?at(r.STENCIL_TEST):At(r.STENCIL_TEST))},setMask:function(ie){rt!==ie&&!N&&(r.stencilMask(ie),rt=ie)},setFunc:function(ie,pn,Un){(W!==ie||$!==pn||ut!==Un)&&(r.stencilFunc(ie,pn,Un),W=ie,$=pn,ut=Un)},setOp:function(ie,pn,Un){(ct!==ie||Dt!==pn||Me!==Un)&&(r.stencilOp(ie,pn,Un),ct=ie,Dt=pn,Me=Un)},setLocked:function(ie){N=ie},setClear:function(ie){Fe!==ie&&(r.clearStencil(ie),Fe=ie)},reset:function(){N=!1,rt=null,W=null,$=null,ut=null,ct=null,Dt=null,Me=null,Fe=null}}}const s=new e,a=new n,o=new i,l=new WeakMap,c=new WeakMap;let h={},u={},d=new WeakMap,f=[],m=null,v=!1,g=null,p=null,x=null,y=null,_=null,I=null,E=null,A=new dt(0,0,0),C=0,b=!1,M=null,L=null,z=null,R=null,B=null;const j=r.getParameter(r.MAX_COMBINED_TEXTURE_IMAGE_UNITS);let X=!1,Q=0;const G=r.getParameter(r.VERSION);G.indexOf("WebGL")!==-1?(Q=parseFloat(/^WebGL (\d)/.exec(G)[1]),X=Q>=1):G.indexOf("OpenGL ES")!==-1&&(Q=parseFloat(/^OpenGL ES (\d)/.exec(G)[1]),X=Q>=2);let it=null,lt={};const St=r.getParameter(r.SCISSOR_BOX),kt=r.getParameter(r.VIEWPORT),ce=new Qt().fromArray(St),Y=new Qt().fromArray(kt);function et(N,rt,W,$){const ut=new Uint8Array(4),ct=r.createTexture();r.bindTexture(N,ct),r.texParameteri(N,r.TEXTURE_MIN_FILTER,r.NEAREST),r.texParameteri(N,r.TEXTURE_MAG_FILTER,r.NEAREST);for(let Dt=0;Dt<W;Dt++)N===r.TEXTURE_3D||N===r.TEXTURE_2D_ARRAY?r.texImage3D(rt,0,r.RGBA,1,1,$,0,r.RGBA,r.UNSIGNED_BYTE,ut):r.texImage2D(rt+Dt,0,r.RGBA,1,1,0,r.RGBA,r.UNSIGNED_BYTE,ut);return ct}const yt={};yt[r.TEXTURE_2D]=et(r.TEXTURE_2D,r.TEXTURE_2D,1),yt[r.TEXTURE_CUBE_MAP]=et(r.TEXTURE_CUBE_MAP,r.TEXTURE_CUBE_MAP_POSITIVE_X,6),yt[r.TEXTURE_2D_ARRAY]=et(r.TEXTURE_2D_ARRAY,r.TEXTURE_2D_ARRAY,1,1),yt[r.TEXTURE_3D]=et(r.TEXTURE_3D,r.TEXTURE_3D,1,1),s.setClear(0,0,0,1),a.setClear(1),o.setClear(0),at(r.DEPTH_TEST),a.setFunc(as),Gt(!1),Wt(kl),at(r.CULL_FACE),O($n);function at(N){h[N]!==!0&&(r.enable(N),h[N]=!0)}function At(N){h[N]!==!1&&(r.disable(N),h[N]=!1)}function Lt(N,rt){return u[N]!==rt?(r.bindFramebuffer(N,rt),u[N]=rt,N===r.DRAW_FRAMEBUFFER&&(u[r.FRAMEBUFFER]=rt),N===r.FRAMEBUFFER&&(u[r.DRAW_FRAMEBUFFER]=rt),!0):!1}function Bt(N,rt){let W=f,$=!1;if(N){W=d.get(rt),W===void 0&&(W=[],d.set(rt,W));const ut=N.textures;if(W.length!==ut.length||W[0]!==r.COLOR_ATTACHMENT0){for(let ct=0,Dt=ut.length;ct<Dt;ct++)W[ct]=r.COLOR_ATTACHMENT0+ct;W.length=ut.length,$=!0}}else W[0]!==r.BACK&&(W[0]=r.BACK,$=!0);$&&r.drawBuffers(W)}function ve(N){return m!==N?(r.useProgram(N),m=N,!0):!1}const Yt={[Li]:r.FUNC_ADD,[ed]:r.FUNC_SUBTRACT,[nd]:r.FUNC_REVERSE_SUBTRACT};Yt[id]=r.MIN,Yt[sd]=r.MAX;const Se={[rd]:r.ZERO,[ad]:r.ONE,[od]:r.SRC_COLOR,[no]:r.SRC_ALPHA,[fd]:r.SRC_ALPHA_SATURATE,[ud]:r.DST_COLOR,[cd]:r.DST_ALPHA,[ld]:r.ONE_MINUS_SRC_COLOR,[io]:r.ONE_MINUS_SRC_ALPHA,[dd]:r.ONE_MINUS_DST_COLOR,[hd]:r.ONE_MINUS_DST_ALPHA,[pd]:r.CONSTANT_COLOR,[md]:r.ONE_MINUS_CONSTANT_COLOR,[gd]:r.CONSTANT_ALPHA,[vd]:r.ONE_MINUS_CONSTANT_ALPHA};function O(N,rt,W,$,ut,ct,Dt,Me,Fe,ie){if(N===$n){v===!0&&(At(r.BLEND),v=!1);return}if(v===!1&&(at(r.BLEND),v=!0),N!==td){if(N!==g||ie!==b){if((p!==Li||_!==Li)&&(r.blendEquation(r.FUNC_ADD),p=Li,_=Li),ie)switch(N){case mi:r.blendFuncSeparate(r.ONE,r.ONE_MINUS_SRC_ALPHA,r.ONE,r.ONE_MINUS_SRC_ALPHA);break;case dn:r.blendFunc(r.ONE,r.ONE);break;case Bl:r.blendFuncSeparate(r.ZERO,r.ONE_MINUS_SRC_COLOR,r.ZERO,r.ONE);break;case zl:r.blendFuncSeparate(r.ZERO,r.SRC_COLOR,r.ZERO,r.SRC_ALPHA);break;default:console.error("THREE.WebGLState: Invalid blending: ",N);break}else switch(N){case mi:r.blendFuncSeparate(r.SRC_ALPHA,r.ONE_MINUS_SRC_ALPHA,r.ONE,r.ONE_MINUS_SRC_ALPHA);break;case dn:r.blendFunc(r.SRC_ALPHA,r.ONE);break;case Bl:r.blendFuncSeparate(r.ZERO,r.ONE_MINUS_SRC_COLOR,r.ZERO,r.ONE);break;case zl:r.blendFunc(r.ZERO,r.SRC_COLOR);break;default:console.error("THREE.WebGLState: Invalid blending: ",N);break}x=null,y=null,I=null,E=null,A.set(0,0,0),C=0,g=N,b=ie}return}ut=ut||rt,ct=ct||W,Dt=Dt||$,(rt!==p||ut!==_)&&(r.blendEquationSeparate(Yt[rt],Yt[ut]),p=rt,_=ut),(W!==x||$!==y||ct!==I||Dt!==E)&&(r.blendFuncSeparate(Se[W],Se[$],Se[ct],Se[Dt]),x=W,y=$,I=ct,E=Dt),(Me.equals(A)===!1||Fe!==C)&&(r.blendColor(Me.r,Me.g,Me.b,Fe),A.copy(Me),C=Fe),g=N,b=!1}function nn(N,rt){N.side===hn?At(r.CULL_FACE):at(r.CULL_FACE);let W=N.side===$e;rt&&(W=!W),Gt(W),N.blending===mi&&N.transparent===!1?O($n):O(N.blending,N.blendEquation,N.blendSrc,N.blendDst,N.blendEquationAlpha,N.blendSrcAlpha,N.blendDstAlpha,N.blendColor,N.blendAlpha,N.premultipliedAlpha),a.setFunc(N.depthFunc),a.setTest(N.depthTest),a.setMask(N.depthWrite),s.setMask(N.colorWrite);const $=N.stencilWrite;o.setTest($),$&&(o.setMask(N.stencilWriteMask),o.setFunc(N.stencilFunc,N.stencilRef,N.stencilFuncMask),o.setOp(N.stencilFail,N.stencilZFail,N.stencilZPass)),fe(N.polygonOffset,N.polygonOffsetFactor,N.polygonOffsetUnits),N.alphaToCoverage===!0?at(r.SAMPLE_ALPHA_TO_COVERAGE):At(r.SAMPLE_ALPHA_TO_COVERAGE)}function Gt(N){M!==N&&(N?r.frontFace(r.CW):r.frontFace(r.CCW),M=N)}function Wt(N){N!==Zu?(at(r.CULL_FACE),N!==L&&(N===kl?r.cullFace(r.BACK):N===Ju?r.cullFace(r.FRONT):r.cullFace(r.FRONT_AND_BACK))):At(r.CULL_FACE),L=N}function Tt(N){N!==z&&(X&&r.lineWidth(N),z=N)}function fe(N,rt,W){N?(at(r.POLYGON_OFFSET_FILL),(R!==rt||B!==W)&&(r.polygonOffset(rt,W),R=rt,B=W)):At(r.POLYGON_OFFSET_FILL)}function wt(N){N?at(r.SCISSOR_TEST):At(r.SCISSOR_TEST)}function T(N){N===void 0&&(N=r.TEXTURE0+j-1),it!==N&&(r.activeTexture(N),it=N)}function S(N,rt,W){W===void 0&&(it===null?W=r.TEXTURE0+j-1:W=it);let $=lt[W];$===void 0&&($={type:void 0,texture:void 0},lt[W]=$),($.type!==N||$.texture!==rt)&&(it!==W&&(r.activeTexture(W),it=W),r.bindTexture(N,rt||yt[N]),$.type=N,$.texture=rt)}function k(){const N=lt[it];N!==void 0&&N.type!==void 0&&(r.bindTexture(N.type,null),N.type=void 0,N.texture=void 0)}function K(){try{r.compressedTexImage2D.apply(r,arguments)}catch(N){console.error("THREE.WebGLState:",N)}}function Z(){try{r.compressedTexImage3D.apply(r,arguments)}catch(N){console.error("THREE.WebGLState:",N)}}function q(){try{r.texSubImage2D.apply(r,arguments)}catch(N){console.error("THREE.WebGLState:",N)}}function Mt(){try{r.texSubImage3D.apply(r,arguments)}catch(N){console.error("THREE.WebGLState:",N)}}function ot(){try{r.compressedTexSubImage2D.apply(r,arguments)}catch(N){console.error("THREE.WebGLState:",N)}}function ft(){try{r.compressedTexSubImage3D.apply(r,arguments)}catch(N){console.error("THREE.WebGLState:",N)}}function Kt(){try{r.texStorage2D.apply(r,arguments)}catch(N){console.error("THREE.WebGLState:",N)}}function J(){try{r.texStorage3D.apply(r,arguments)}catch(N){console.error("THREE.WebGLState:",N)}}function pt(){try{r.texImage2D.apply(r,arguments)}catch(N){console.error("THREE.WebGLState:",N)}}function Et(){try{r.texImage3D.apply(r,arguments)}catch(N){console.error("THREE.WebGLState:",N)}}function Ct(N){ce.equals(N)===!1&&(r.scissor(N.x,N.y,N.z,N.w),ce.copy(N))}function mt(N){Y.equals(N)===!1&&(r.viewport(N.x,N.y,N.z,N.w),Y.copy(N))}function Xt(N,rt){let W=c.get(rt);W===void 0&&(W=new WeakMap,c.set(rt,W));let $=W.get(N);$===void 0&&($=r.getUniformBlockIndex(rt,N.name),W.set(N,$))}function Ft(N,rt){const $=c.get(rt).get(N);l.get(rt)!==$&&(r.uniformBlockBinding(rt,$,N.__bindingPointIndex),l.set(rt,$))}function ue(){r.disable(r.BLEND),r.disable(r.CULL_FACE),r.disable(r.DEPTH_TEST),r.disable(r.POLYGON_OFFSET_FILL),r.disable(r.SCISSOR_TEST),r.disable(r.STENCIL_TEST),r.disable(r.SAMPLE_ALPHA_TO_COVERAGE),r.blendEquation(r.FUNC_ADD),r.blendFunc(r.ONE,r.ZERO),r.blendFuncSeparate(r.ONE,r.ZERO,r.ONE,r.ZERO),r.blendColor(0,0,0,0),r.colorMask(!0,!0,!0,!0),r.clearColor(0,0,0,0),r.depthMask(!0),r.depthFunc(r.LESS),a.setReversed(!1),r.clearDepth(1),r.stencilMask(4294967295),r.stencilFunc(r.ALWAYS,0,4294967295),r.stencilOp(r.KEEP,r.KEEP,r.KEEP),r.clearStencil(0),r.cullFace(r.BACK),r.frontFace(r.CCW),r.polygonOffset(0,0),r.activeTexture(r.TEXTURE0),r.bindFramebuffer(r.FRAMEBUFFER,null),r.bindFramebuffer(r.DRAW_FRAMEBUFFER,null),r.bindFramebuffer(r.READ_FRAMEBUFFER,null),r.useProgram(null),r.lineWidth(1),r.scissor(0,0,r.canvas.width,r.canvas.height),r.viewport(0,0,r.canvas.width,r.canvas.height),h={},it=null,lt={},u={},d=new WeakMap,f=[],m=null,v=!1,g=null,p=null,x=null,y=null,_=null,I=null,E=null,A=new dt(0,0,0),C=0,b=!1,M=null,L=null,z=null,R=null,B=null,ce.set(0,0,r.canvas.width,r.canvas.height),Y.set(0,0,r.canvas.width,r.canvas.height),s.reset(),a.reset(),o.reset()}return{buffers:{color:s,depth:a,stencil:o},enable:at,disable:At,bindFramebuffer:Lt,drawBuffers:Bt,useProgram:ve,setBlending:O,setMaterial:nn,setFlipSided:Gt,setCullFace:Wt,setLineWidth:Tt,setPolygonOffset:fe,setScissorTest:wt,activeTexture:T,bindTexture:S,unbindTexture:k,compressedTexImage2D:K,compressedTexImage3D:Z,texImage2D:pt,texImage3D:Et,updateUBOMapping:Xt,uniformBlockBinding:Ft,texStorage2D:Kt,texStorage3D:J,texSubImage2D:q,texSubImage3D:Mt,compressedTexSubImage2D:ot,compressedTexSubImage3D:ft,scissor:Ct,viewport:mt,reset:ue}}function kc(r,t,e,n){const i=j0(n);switch(e){case Vh:return r*t;case Wh:return r*t;case Xh:return r*t*2;case al:return r*t/i.components*i.byteLength;case ol:return r*t/i.components*i.byteLength;case qh:return r*t*2/i.components*i.byteLength;case ll:return r*t*2/i.components*i.byteLength;case Gh:return r*t*3/i.components*i.byteLength;case un:return r*t*4/i.components*i.byteLength;case cl:return r*t*4/i.components*i.byteLength;case zr:case Hr:return Math.floor((r+3)/4)*Math.floor((t+3)/4)*8;case Vr:case Gr:return Math.floor((r+3)/4)*Math.floor((t+3)/4)*16;case mo:case vo:return Math.max(r,16)*Math.max(t,8)/4;case po:case go:return Math.max(r,8)*Math.max(t,8)/2;case _o:case xo:return Math.floor((r+3)/4)*Math.floor((t+3)/4)*8;case yo:return Math.floor((r+3)/4)*Math.floor((t+3)/4)*16;case Mo:return Math.floor((r+3)/4)*Math.floor((t+3)/4)*16;case bo:return Math.floor((r+4)/5)*Math.floor((t+3)/4)*16;case So:return Math.floor((r+4)/5)*Math.floor((t+4)/5)*16;case wo:return Math.floor((r+5)/6)*Math.floor((t+4)/5)*16;case To:return Math.floor((r+5)/6)*Math.floor((t+5)/6)*16;case Eo:return Math.floor((r+7)/8)*Math.floor((t+4)/5)*16;case Ao:return Math.floor((r+7)/8)*Math.floor((t+5)/6)*16;case Ro:return Math.floor((r+7)/8)*Math.floor((t+7)/8)*16;case Co:return Math.floor((r+9)/10)*Math.floor((t+4)/5)*16;case Po:return Math.floor((r+9)/10)*Math.floor((t+5)/6)*16;case Lo:return Math.floor((r+9)/10)*Math.floor((t+7)/8)*16;case Io:return Math.floor((r+9)/10)*Math.floor((t+9)/10)*16;case Do:return Math.floor((r+11)/12)*Math.floor((t+9)/10)*16;case No:return Math.floor((r+11)/12)*Math.floor((t+11)/12)*16;case Wr:case Uo:case Fo:return Math.ceil(r/4)*Math.ceil(t/4)*16;case Yh:case Oo:return Math.ceil(r/4)*Math.ceil(t/4)*8;case ko:case Bo:return Math.ceil(r/4)*Math.ceil(t/4)*16}throw new Error(`Unable to determine texture byte length for ${e} format.`)}function j0(r){switch(r){case Jn:case Bh:return{byteLength:1,components:1};case Ks:case zh:case Pn:return{byteLength:2,components:1};case sl:case rl:return{byteLength:2,components:4};case Ui:case il:case Sn:return{byteLength:4,components:1};case Hh:return{byteLength:4,components:3}}throw new Error(`Unknown texture type ${r}.`)}function Z0(r,t,e,n,i,s,a){const o=t.has("WEBGL_multisampled_render_to_texture")?t.get("WEBGL_multisampled_render_to_texture"):null,l=typeof navigator>"u"?!1:/OculusBrowser/g.test(navigator.userAgent),c=new nt,h=new WeakMap;let u;const d=new WeakMap;let f=!1;try{f=typeof OffscreenCanvas<"u"&&new OffscreenCanvas(1,1).getContext("2d")!==null}catch{}function m(T,S){return f?new OffscreenCanvas(T,S):Zs("canvas")}function v(T,S,k){let K=1;const Z=wt(T);if((Z.width>k||Z.height>k)&&(K=k/Math.max(Z.width,Z.height)),K<1)if(typeof HTMLImageElement<"u"&&T instanceof HTMLImageElement||typeof HTMLCanvasElement<"u"&&T instanceof HTMLCanvasElement||typeof ImageBitmap<"u"&&T instanceof ImageBitmap||typeof VideoFrame<"u"&&T instanceof VideoFrame){const q=Math.floor(K*Z.width),Mt=Math.floor(K*Z.height);u===void 0&&(u=m(q,Mt));const ot=S?m(q,Mt):u;return ot.width=q,ot.height=Mt,ot.getContext("2d").drawImage(T,0,0,q,Mt),console.warn("THREE.WebGLRenderer: Texture has been resized from ("+Z.width+"x"+Z.height+") to ("+q+"x"+Mt+")."),ot}else return"data"in T&&console.warn("THREE.WebGLRenderer: Image in DataTexture is too big ("+Z.width+"x"+Z.height+")."),T;return T}function g(T){return T.generateMipmaps}function p(T){r.generateMipmap(T)}function x(T){return T.isWebGLCubeRenderTarget?r.TEXTURE_CUBE_MAP:T.isWebGL3DRenderTarget?r.TEXTURE_3D:T.isWebGLArrayRenderTarget||T.isCompressedArrayTexture?r.TEXTURE_2D_ARRAY:r.TEXTURE_2D}function y(T,S,k,K,Z=!1){if(T!==null){if(r[T]!==void 0)return r[T];console.warn("THREE.WebGLRenderer: Attempt to use non-existing WebGL internal format '"+T+"'")}let q=S;if(S===r.RED&&(k===r.FLOAT&&(q=r.R32F),k===r.HALF_FLOAT&&(q=r.R16F),k===r.UNSIGNED_BYTE&&(q=r.R8)),S===r.RED_INTEGER&&(k===r.UNSIGNED_BYTE&&(q=r.R8UI),k===r.UNSIGNED_SHORT&&(q=r.R16UI),k===r.UNSIGNED_INT&&(q=r.R32UI),k===r.BYTE&&(q=r.R8I),k===r.SHORT&&(q=r.R16I),k===r.INT&&(q=r.R32I)),S===r.RG&&(k===r.FLOAT&&(q=r.RG32F),k===r.HALF_FLOAT&&(q=r.RG16F),k===r.UNSIGNED_BYTE&&(q=r.RG8)),S===r.RG_INTEGER&&(k===r.UNSIGNED_BYTE&&(q=r.RG8UI),k===r.UNSIGNED_SHORT&&(q=r.RG16UI),k===r.UNSIGNED_INT&&(q=r.RG32UI),k===r.BYTE&&(q=r.RG8I),k===r.SHORT&&(q=r.RG16I),k===r.INT&&(q=r.RG32I)),S===r.RGB_INTEGER&&(k===r.UNSIGNED_BYTE&&(q=r.RGB8UI),k===r.UNSIGNED_SHORT&&(q=r.RGB16UI),k===r.UNSIGNED_INT&&(q=r.RGB32UI),k===r.BYTE&&(q=r.RGB8I),k===r.SHORT&&(q=r.RGB16I),k===r.INT&&(q=r.RGB32I)),S===r.RGBA_INTEGER&&(k===r.UNSIGNED_BYTE&&(q=r.RGBA8UI),k===r.UNSIGNED_SHORT&&(q=r.RGBA16UI),k===r.UNSIGNED_INT&&(q=r.RGBA32UI),k===r.BYTE&&(q=r.RGBA8I),k===r.SHORT&&(q=r.RGBA16I),k===r.INT&&(q=r.RGBA32I)),S===r.RGB&&k===r.UNSIGNED_INT_5_9_9_9_REV&&(q=r.RGB9_E5),S===r.RGBA){const Mt=Z?sa:Ht.getTransfer(K);k===r.FLOAT&&(q=r.RGBA32F),k===r.HALF_FLOAT&&(q=r.RGBA16F),k===r.UNSIGNED_BYTE&&(q=Mt===se?r.SRGB8_ALPHA8:r.RGBA8),k===r.UNSIGNED_SHORT_4_4_4_4&&(q=r.RGBA4),k===r.UNSIGNED_SHORT_5_5_5_1&&(q=r.RGB5_A1)}return(q===r.R16F||q===r.R32F||q===r.RG16F||q===r.RG32F||q===r.RGBA16F||q===r.RGBA32F)&&t.get("EXT_color_buffer_float"),q}function _(T,S){let k;return T?S===null||S===Ui||S===cs?k=r.DEPTH24_STENCIL8:S===Sn?k=r.DEPTH32F_STENCIL8:S===Ks&&(k=r.DEPTH24_STENCIL8,console.warn("DepthTexture: 16 bit depth attachment is not supported with stencil. Using 24-bit attachment.")):S===null||S===Ui||S===cs?k=r.DEPTH_COMPONENT24:S===Sn?k=r.DEPTH_COMPONENT32F:S===Ks&&(k=r.DEPTH_COMPONENT16),k}function I(T,S){return g(T)===!0||T.isFramebufferTexture&&T.minFilter!==Xe&&T.minFilter!==tn?Math.log2(Math.max(S.width,S.height))+1:T.mipmaps!==void 0&&T.mipmaps.length>0?T.mipmaps.length:T.isCompressedTexture&&Array.isArray(T.image)?S.mipmaps.length:1}function E(T){const S=T.target;S.removeEventListener("dispose",E),C(S),S.isVideoTexture&&h.delete(S)}function A(T){const S=T.target;S.removeEventListener("dispose",A),M(S)}function C(T){const S=n.get(T);if(S.__webglInit===void 0)return;const k=T.source,K=d.get(k);if(K){const Z=K[S.__cacheKey];Z.usedTimes--,Z.usedTimes===0&&b(T),Object.keys(K).length===0&&d.delete(k)}n.remove(T)}function b(T){const S=n.get(T);r.deleteTexture(S.__webglTexture);const k=T.source,K=d.get(k);delete K[S.__cacheKey],a.memory.textures--}function M(T){const S=n.get(T);if(T.depthTexture&&(T.depthTexture.dispose(),n.remove(T.depthTexture)),T.isWebGLCubeRenderTarget)for(let K=0;K<6;K++){if(Array.isArray(S.__webglFramebuffer[K]))for(let Z=0;Z<S.__webglFramebuffer[K].length;Z++)r.deleteFramebuffer(S.__webglFramebuffer[K][Z]);else r.deleteFramebuffer(S.__webglFramebuffer[K]);S.__webglDepthbuffer&&r.deleteRenderbuffer(S.__webglDepthbuffer[K])}else{if(Array.isArray(S.__webglFramebuffer))for(let K=0;K<S.__webglFramebuffer.length;K++)r.deleteFramebuffer(S.__webglFramebuffer[K]);else r.deleteFramebuffer(S.__webglFramebuffer);if(S.__webglDepthbuffer&&r.deleteRenderbuffer(S.__webglDepthbuffer),S.__webglMultisampledFramebuffer&&r.deleteFramebuffer(S.__webglMultisampledFramebuffer),S.__webglColorRenderbuffer)for(let K=0;K<S.__webglColorRenderbuffer.length;K++)S.__webglColorRenderbuffer[K]&&r.deleteRenderbuffer(S.__webglColorRenderbuffer[K]);S.__webglDepthRenderbuffer&&r.deleteRenderbuffer(S.__webglDepthRenderbuffer)}const k=T.textures;for(let K=0,Z=k.length;K<Z;K++){const q=n.get(k[K]);q.__webglTexture&&(r.deleteTexture(q.__webglTexture),a.memory.textures--),n.remove(k[K])}n.remove(T)}let L=0;function z(){L=0}function R(){const T=L;return T>=i.maxTextures&&console.warn("THREE.WebGLTextures: Trying to use "+T+" texture units while this GPU supports only "+i.maxTextures),L+=1,T}function B(T){const S=[];return S.push(T.wrapS),S.push(T.wrapT),S.push(T.wrapR||0),S.push(T.magFilter),S.push(T.minFilter),S.push(T.anisotropy),S.push(T.internalFormat),S.push(T.format),S.push(T.type),S.push(T.generateMipmaps),S.push(T.premultiplyAlpha),S.push(T.flipY),S.push(T.unpackAlignment),S.push(T.colorSpace),S.join()}function j(T,S){const k=n.get(T);if(T.isVideoTexture&&Tt(T),T.isRenderTargetTexture===!1&&T.version>0&&k.__version!==T.version){const K=T.image;if(K===null)console.warn("THREE.WebGLRenderer: Texture marked for update but no image data found.");else if(K.complete===!1)console.warn("THREE.WebGLRenderer: Texture marked for update but image is incomplete");else{Y(k,T,S);return}}e.bindTexture(r.TEXTURE_2D,k.__webglTexture,r.TEXTURE0+S)}function X(T,S){const k=n.get(T);if(T.version>0&&k.__version!==T.version){Y(k,T,S);return}e.bindTexture(r.TEXTURE_2D_ARRAY,k.__webglTexture,r.TEXTURE0+S)}function Q(T,S){const k=n.get(T);if(T.version>0&&k.__version!==T.version){Y(k,T,S);return}e.bindTexture(r.TEXTURE_3D,k.__webglTexture,r.TEXTURE0+S)}function G(T,S){const k=n.get(T);if(T.version>0&&k.__version!==T.version){et(k,T,S);return}e.bindTexture(r.TEXTURE_CUBE_MAP,k.__webglTexture,r.TEXTURE0+S)}const it={[vi]:r.REPEAT,[fi]:r.CLAMP_TO_EDGE,[$r]:r.MIRRORED_REPEAT},lt={[Xe]:r.NEAREST,[kh]:r.NEAREST_MIPMAP_NEAREST,[Bs]:r.NEAREST_MIPMAP_LINEAR,[tn]:r.LINEAR,[Br]:r.LINEAR_MIPMAP_NEAREST,[qn]:r.LINEAR_MIPMAP_LINEAR},St={[Ad]:r.NEVER,[Dd]:r.ALWAYS,[Rd]:r.LESS,[$h]:r.LEQUAL,[Cd]:r.EQUAL,[Id]:r.GEQUAL,[Pd]:r.GREATER,[Ld]:r.NOTEQUAL};function kt(T,S){if(S.type===Sn&&t.has("OES_texture_float_linear")===!1&&(S.magFilter===tn||S.magFilter===Br||S.magFilter===Bs||S.magFilter===qn||S.minFilter===tn||S.minFilter===Br||S.minFilter===Bs||S.minFilter===qn)&&console.warn("THREE.WebGLRenderer: Unable to use linear filtering with floating point textures. OES_texture_float_linear not supported on this device."),r.texParameteri(T,r.TEXTURE_WRAP_S,it[S.wrapS]),r.texParameteri(T,r.TEXTURE_WRAP_T,it[S.wrapT]),(T===r.TEXTURE_3D||T===r.TEXTURE_2D_ARRAY)&&r.texParameteri(T,r.TEXTURE_WRAP_R,it[S.wrapR]),r.texParameteri(T,r.TEXTURE_MAG_FILTER,lt[S.magFilter]),r.texParameteri(T,r.TEXTURE_MIN_FILTER,lt[S.minFilter]),S.compareFunction&&(r.texParameteri(T,r.TEXTURE_COMPARE_MODE,r.COMPARE_REF_TO_TEXTURE),r.texParameteri(T,r.TEXTURE_COMPARE_FUNC,St[S.compareFunction])),t.has("EXT_texture_filter_anisotropic")===!0){if(S.magFilter===Xe||S.minFilter!==Bs&&S.minFilter!==qn||S.type===Sn&&t.has("OES_texture_float_linear")===!1)return;if(S.anisotropy>1||n.get(S).__currentAnisotropy){const k=t.get("EXT_texture_filter_anisotropic");r.texParameterf(T,k.TEXTURE_MAX_ANISOTROPY_EXT,Math.min(S.anisotropy,i.getMaxAnisotropy())),n.get(S).__currentAnisotropy=S.anisotropy}}}function ce(T,S){let k=!1;T.__webglInit===void 0&&(T.__webglInit=!0,S.addEventListener("dispose",E));const K=S.source;let Z=d.get(K);Z===void 0&&(Z={},d.set(K,Z));const q=B(S);if(q!==T.__cacheKey){Z[q]===void 0&&(Z[q]={texture:r.createTexture(),usedTimes:0},a.memory.textures++,k=!0),Z[q].usedTimes++;const Mt=Z[T.__cacheKey];Mt!==void 0&&(Z[T.__cacheKey].usedTimes--,Mt.usedTimes===0&&b(S)),T.__cacheKey=q,T.__webglTexture=Z[q].texture}return k}function Y(T,S,k){let K=r.TEXTURE_2D;(S.isDataArrayTexture||S.isCompressedArrayTexture)&&(K=r.TEXTURE_2D_ARRAY),S.isData3DTexture&&(K=r.TEXTURE_3D);const Z=ce(T,S),q=S.source;e.bindTexture(K,T.__webglTexture,r.TEXTURE0+k);const Mt=n.get(q);if(q.version!==Mt.__version||Z===!0){e.activeTexture(r.TEXTURE0+k);const ot=Ht.getPrimaries(Ht.workingColorSpace),ft=S.colorSpace===di?null:Ht.getPrimaries(S.colorSpace),Kt=S.colorSpace===di||ot===ft?r.NONE:r.BROWSER_DEFAULT_WEBGL;r.pixelStorei(r.UNPACK_FLIP_Y_WEBGL,S.flipY),r.pixelStorei(r.UNPACK_PREMULTIPLY_ALPHA_WEBGL,S.premultiplyAlpha),r.pixelStorei(r.UNPACK_ALIGNMENT,S.unpackAlignment),r.pixelStorei(r.UNPACK_COLORSPACE_CONVERSION_WEBGL,Kt);let J=v(S.image,!1,i.maxTextureSize);J=fe(S,J);const pt=s.convert(S.format,S.colorSpace),Et=s.convert(S.type);let Ct=y(S.internalFormat,pt,Et,S.colorSpace,S.isVideoTexture);kt(K,S);let mt;const Xt=S.mipmaps,Ft=S.isVideoTexture!==!0,ue=Mt.__version===void 0||Z===!0,N=q.dataReady,rt=I(S,J);if(S.isDepthTexture)Ct=_(S.format===hs,S.type),ue&&(Ft?e.texStorage2D(r.TEXTURE_2D,1,Ct,J.width,J.height):e.texImage2D(r.TEXTURE_2D,0,Ct,J.width,J.height,0,pt,Et,null));else if(S.isDataTexture)if(Xt.length>0){Ft&&ue&&e.texStorage2D(r.TEXTURE_2D,rt,Ct,Xt[0].width,Xt[0].height);for(let W=0,$=Xt.length;W<$;W++)mt=Xt[W],Ft?N&&e.texSubImage2D(r.TEXTURE_2D,W,0,0,mt.width,mt.height,pt,Et,mt.data):e.texImage2D(r.TEXTURE_2D,W,Ct,mt.width,mt.height,0,pt,Et,mt.data);S.generateMipmaps=!1}else Ft?(ue&&e.texStorage2D(r.TEXTURE_2D,rt,Ct,J.width,J.height),N&&e.texSubImage2D(r.TEXTURE_2D,0,0,0,J.width,J.height,pt,Et,J.data)):e.texImage2D(r.TEXTURE_2D,0,Ct,J.width,J.height,0,pt,Et,J.data);else if(S.isCompressedTexture)if(S.isCompressedArrayTexture){Ft&&ue&&e.texStorage3D(r.TEXTURE_2D_ARRAY,rt,Ct,Xt[0].width,Xt[0].height,J.depth);for(let W=0,$=Xt.length;W<$;W++)if(mt=Xt[W],S.format!==un)if(pt!==null)if(Ft){if(N)if(S.layerUpdates.size>0){const ut=kc(mt.width,mt.height,S.format,S.type);for(const ct of S.layerUpdates){const Dt=mt.data.subarray(ct*ut/mt.data.BYTES_PER_ELEMENT,(ct+1)*ut/mt.data.BYTES_PER_ELEMENT);e.compressedTexSubImage3D(r.TEXTURE_2D_ARRAY,W,0,0,ct,mt.width,mt.height,1,pt,Dt)}S.clearLayerUpdates()}else e.compressedTexSubImage3D(r.TEXTURE_2D_ARRAY,W,0,0,0,mt.width,mt.height,J.depth,pt,mt.data)}else e.compressedTexImage3D(r.TEXTURE_2D_ARRAY,W,Ct,mt.width,mt.height,J.depth,0,mt.data,0,0);else console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()");else Ft?N&&e.texSubImage3D(r.TEXTURE_2D_ARRAY,W,0,0,0,mt.width,mt.height,J.depth,pt,Et,mt.data):e.texImage3D(r.TEXTURE_2D_ARRAY,W,Ct,mt.width,mt.height,J.depth,0,pt,Et,mt.data)}else{Ft&&ue&&e.texStorage2D(r.TEXTURE_2D,rt,Ct,Xt[0].width,Xt[0].height);for(let W=0,$=Xt.length;W<$;W++)mt=Xt[W],S.format!==un?pt!==null?Ft?N&&e.compressedTexSubImage2D(r.TEXTURE_2D,W,0,0,mt.width,mt.height,pt,mt.data):e.compressedTexImage2D(r.TEXTURE_2D,W,Ct,mt.width,mt.height,0,mt.data):console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()"):Ft?N&&e.texSubImage2D(r.TEXTURE_2D,W,0,0,mt.width,mt.height,pt,Et,mt.data):e.texImage2D(r.TEXTURE_2D,W,Ct,mt.width,mt.height,0,pt,Et,mt.data)}else if(S.isDataArrayTexture)if(Ft){if(ue&&e.texStorage3D(r.TEXTURE_2D_ARRAY,rt,Ct,J.width,J.height,J.depth),N)if(S.layerUpdates.size>0){const W=kc(J.width,J.height,S.format,S.type);for(const $ of S.layerUpdates){const ut=J.data.subarray($*W/J.data.BYTES_PER_ELEMENT,($+1)*W/J.data.BYTES_PER_ELEMENT);e.texSubImage3D(r.TEXTURE_2D_ARRAY,0,0,0,$,J.width,J.height,1,pt,Et,ut)}S.clearLayerUpdates()}else e.texSubImage3D(r.TEXTURE_2D_ARRAY,0,0,0,0,J.width,J.height,J.depth,pt,Et,J.data)}else e.texImage3D(r.TEXTURE_2D_ARRAY,0,Ct,J.width,J.height,J.depth,0,pt,Et,J.data);else if(S.isData3DTexture)Ft?(ue&&e.texStorage3D(r.TEXTURE_3D,rt,Ct,J.width,J.height,J.depth),N&&e.texSubImage3D(r.TEXTURE_3D,0,0,0,0,J.width,J.height,J.depth,pt,Et,J.data)):e.texImage3D(r.TEXTURE_3D,0,Ct,J.width,J.height,J.depth,0,pt,Et,J.data);else if(S.isFramebufferTexture){if(ue)if(Ft)e.texStorage2D(r.TEXTURE_2D,rt,Ct,J.width,J.height);else{let W=J.width,$=J.height;for(let ut=0;ut<rt;ut++)e.texImage2D(r.TEXTURE_2D,ut,Ct,W,$,0,pt,Et,null),W>>=1,$>>=1}}else if(Xt.length>0){if(Ft&&ue){const W=wt(Xt[0]);e.texStorage2D(r.TEXTURE_2D,rt,Ct,W.width,W.height)}for(let W=0,$=Xt.length;W<$;W++)mt=Xt[W],Ft?N&&e.texSubImage2D(r.TEXTURE_2D,W,0,0,pt,Et,mt):e.texImage2D(r.TEXTURE_2D,W,Ct,pt,Et,mt);S.generateMipmaps=!1}else if(Ft){if(ue){const W=wt(J);e.texStorage2D(r.TEXTURE_2D,rt,Ct,W.width,W.height)}N&&e.texSubImage2D(r.TEXTURE_2D,0,0,0,pt,Et,J)}else e.texImage2D(r.TEXTURE_2D,0,Ct,pt,Et,J);g(S)&&p(K),Mt.__version=q.version,S.onUpdate&&S.onUpdate(S)}T.__version=S.version}function et(T,S,k){if(S.image.length!==6)return;const K=ce(T,S),Z=S.source;e.bindTexture(r.TEXTURE_CUBE_MAP,T.__webglTexture,r.TEXTURE0+k);const q=n.get(Z);if(Z.version!==q.__version||K===!0){e.activeTexture(r.TEXTURE0+k);const Mt=Ht.getPrimaries(Ht.workingColorSpace),ot=S.colorSpace===di?null:Ht.getPrimaries(S.colorSpace),ft=S.colorSpace===di||Mt===ot?r.NONE:r.BROWSER_DEFAULT_WEBGL;r.pixelStorei(r.UNPACK_FLIP_Y_WEBGL,S.flipY),r.pixelStorei(r.UNPACK_PREMULTIPLY_ALPHA_WEBGL,S.premultiplyAlpha),r.pixelStorei(r.UNPACK_ALIGNMENT,S.unpackAlignment),r.pixelStorei(r.UNPACK_COLORSPACE_CONVERSION_WEBGL,ft);const Kt=S.isCompressedTexture||S.image[0].isCompressedTexture,J=S.image[0]&&S.image[0].isDataTexture,pt=[];for(let $=0;$<6;$++)!Kt&&!J?pt[$]=v(S.image[$],!0,i.maxCubemapSize):pt[$]=J?S.image[$].image:S.image[$],pt[$]=fe(S,pt[$]);const Et=pt[0],Ct=s.convert(S.format,S.colorSpace),mt=s.convert(S.type),Xt=y(S.internalFormat,Ct,mt,S.colorSpace),Ft=S.isVideoTexture!==!0,ue=q.__version===void 0||K===!0,N=Z.dataReady;let rt=I(S,Et);kt(r.TEXTURE_CUBE_MAP,S);let W;if(Kt){Ft&&ue&&e.texStorage2D(r.TEXTURE_CUBE_MAP,rt,Xt,Et.width,Et.height);for(let $=0;$<6;$++){W=pt[$].mipmaps;for(let ut=0;ut<W.length;ut++){const ct=W[ut];S.format!==un?Ct!==null?Ft?N&&e.compressedTexSubImage2D(r.TEXTURE_CUBE_MAP_POSITIVE_X+$,ut,0,0,ct.width,ct.height,Ct,ct.data):e.compressedTexImage2D(r.TEXTURE_CUBE_MAP_POSITIVE_X+$,ut,Xt,ct.width,ct.height,0,ct.data):console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .setTextureCube()"):Ft?N&&e.texSubImage2D(r.TEXTURE_CUBE_MAP_POSITIVE_X+$,ut,0,0,ct.width,ct.height,Ct,mt,ct.data):e.texImage2D(r.TEXTURE_CUBE_MAP_POSITIVE_X+$,ut,Xt,ct.width,ct.height,0,Ct,mt,ct.data)}}}else{if(W=S.mipmaps,Ft&&ue){W.length>0&&rt++;const $=wt(pt[0]);e.texStorage2D(r.TEXTURE_CUBE_MAP,rt,Xt,$.width,$.height)}for(let $=0;$<6;$++)if(J){Ft?N&&e.texSubImage2D(r.TEXTURE_CUBE_MAP_POSITIVE_X+$,0,0,0,pt[$].width,pt[$].height,Ct,mt,pt[$].data):e.texImage2D(r.TEXTURE_CUBE_MAP_POSITIVE_X+$,0,Xt,pt[$].width,pt[$].height,0,Ct,mt,pt[$].data);for(let ut=0;ut<W.length;ut++){const Dt=W[ut].image[$].image;Ft?N&&e.texSubImage2D(r.TEXTURE_CUBE_MAP_POSITIVE_X+$,ut+1,0,0,Dt.width,Dt.height,Ct,mt,Dt.data):e.texImage2D(r.TEXTURE_CUBE_MAP_POSITIVE_X+$,ut+1,Xt,Dt.width,Dt.height,0,Ct,mt,Dt.data)}}else{Ft?N&&e.texSubImage2D(r.TEXTURE_CUBE_MAP_POSITIVE_X+$,0,0,0,Ct,mt,pt[$]):e.texImage2D(r.TEXTURE_CUBE_MAP_POSITIVE_X+$,0,Xt,Ct,mt,pt[$]);for(let ut=0;ut<W.length;ut++){const ct=W[ut];Ft?N&&e.texSubImage2D(r.TEXTURE_CUBE_MAP_POSITIVE_X+$,ut+1,0,0,Ct,mt,ct.image[$]):e.texImage2D(r.TEXTURE_CUBE_MAP_POSITIVE_X+$,ut+1,Xt,Ct,mt,ct.image[$])}}}g(S)&&p(r.TEXTURE_CUBE_MAP),q.__version=Z.version,S.onUpdate&&S.onUpdate(S)}T.__version=S.version}function yt(T,S,k,K,Z,q){const Mt=s.convert(k.format,k.colorSpace),ot=s.convert(k.type),ft=y(k.internalFormat,Mt,ot,k.colorSpace),Kt=n.get(S),J=n.get(k);if(J.__renderTarget=S,!Kt.__hasExternalTextures){const pt=Math.max(1,S.width>>q),Et=Math.max(1,S.height>>q);Z===r.TEXTURE_3D||Z===r.TEXTURE_2D_ARRAY?e.texImage3D(Z,q,ft,pt,Et,S.depth,0,Mt,ot,null):e.texImage2D(Z,q,ft,pt,Et,0,Mt,ot,null)}e.bindFramebuffer(r.FRAMEBUFFER,T),Wt(S)?o.framebufferTexture2DMultisampleEXT(r.FRAMEBUFFER,K,Z,J.__webglTexture,0,Gt(S)):(Z===r.TEXTURE_2D||Z>=r.TEXTURE_CUBE_MAP_POSITIVE_X&&Z<=r.TEXTURE_CUBE_MAP_NEGATIVE_Z)&&r.framebufferTexture2D(r.FRAMEBUFFER,K,Z,J.__webglTexture,q),e.bindFramebuffer(r.FRAMEBUFFER,null)}function at(T,S,k){if(r.bindRenderbuffer(r.RENDERBUFFER,T),S.depthBuffer){const K=S.depthTexture,Z=K&&K.isDepthTexture?K.type:null,q=_(S.stencilBuffer,Z),Mt=S.stencilBuffer?r.DEPTH_STENCIL_ATTACHMENT:r.DEPTH_ATTACHMENT,ot=Gt(S);Wt(S)?o.renderbufferStorageMultisampleEXT(r.RENDERBUFFER,ot,q,S.width,S.height):k?r.renderbufferStorageMultisample(r.RENDERBUFFER,ot,q,S.width,S.height):r.renderbufferStorage(r.RENDERBUFFER,q,S.width,S.height),r.framebufferRenderbuffer(r.FRAMEBUFFER,Mt,r.RENDERBUFFER,T)}else{const K=S.textures;for(let Z=0;Z<K.length;Z++){const q=K[Z],Mt=s.convert(q.format,q.colorSpace),ot=s.convert(q.type),ft=y(q.internalFormat,Mt,ot,q.colorSpace),Kt=Gt(S);k&&Wt(S)===!1?r.renderbufferStorageMultisample(r.RENDERBUFFER,Kt,ft,S.width,S.height):Wt(S)?o.renderbufferStorageMultisampleEXT(r.RENDERBUFFER,Kt,ft,S.width,S.height):r.renderbufferStorage(r.RENDERBUFFER,ft,S.width,S.height)}}r.bindRenderbuffer(r.RENDERBUFFER,null)}function At(T,S){if(S&&S.isWebGLCubeRenderTarget)throw new Error("Depth Texture with cube render targets is not supported");if(e.bindFramebuffer(r.FRAMEBUFFER,T),!(S.depthTexture&&S.depthTexture.isDepthTexture))throw new Error("renderTarget.depthTexture must be an instance of THREE.DepthTexture");const K=n.get(S.depthTexture);K.__renderTarget=S,(!K.__webglTexture||S.depthTexture.image.width!==S.width||S.depthTexture.image.height!==S.height)&&(S.depthTexture.image.width=S.width,S.depthTexture.image.height=S.height,S.depthTexture.needsUpdate=!0),j(S.depthTexture,0);const Z=K.__webglTexture,q=Gt(S);if(S.depthTexture.format===is)Wt(S)?o.framebufferTexture2DMultisampleEXT(r.FRAMEBUFFER,r.DEPTH_ATTACHMENT,r.TEXTURE_2D,Z,0,q):r.framebufferTexture2D(r.FRAMEBUFFER,r.DEPTH_ATTACHMENT,r.TEXTURE_2D,Z,0);else if(S.depthTexture.format===hs)Wt(S)?o.framebufferTexture2DMultisampleEXT(r.FRAMEBUFFER,r.DEPTH_STENCIL_ATTACHMENT,r.TEXTURE_2D,Z,0,q):r.framebufferTexture2D(r.FRAMEBUFFER,r.DEPTH_STENCIL_ATTACHMENT,r.TEXTURE_2D,Z,0);else throw new Error("Unknown depthTexture format")}function Lt(T){const S=n.get(T),k=T.isWebGLCubeRenderTarget===!0;if(S.__boundDepthTexture!==T.depthTexture){const K=T.depthTexture;if(S.__depthDisposeCallback&&S.__depthDisposeCallback(),K){const Z=()=>{delete S.__boundDepthTexture,delete S.__depthDisposeCallback,K.removeEventListener("dispose",Z)};K.addEventListener("dispose",Z),S.__depthDisposeCallback=Z}S.__boundDepthTexture=K}if(T.depthTexture&&!S.__autoAllocateDepthBuffer){if(k)throw new Error("target.depthTexture not supported in Cube render targets");At(S.__webglFramebuffer,T)}else if(k){S.__webglDepthbuffer=[];for(let K=0;K<6;K++)if(e.bindFramebuffer(r.FRAMEBUFFER,S.__webglFramebuffer[K]),S.__webglDepthbuffer[K]===void 0)S.__webglDepthbuffer[K]=r.createRenderbuffer(),at(S.__webglDepthbuffer[K],T,!1);else{const Z=T.stencilBuffer?r.DEPTH_STENCIL_ATTACHMENT:r.DEPTH_ATTACHMENT,q=S.__webglDepthbuffer[K];r.bindRenderbuffer(r.RENDERBUFFER,q),r.framebufferRenderbuffer(r.FRAMEBUFFER,Z,r.RENDERBUFFER,q)}}else if(e.bindFramebuffer(r.FRAMEBUFFER,S.__webglFramebuffer),S.__webglDepthbuffer===void 0)S.__webglDepthbuffer=r.createRenderbuffer(),at(S.__webglDepthbuffer,T,!1);else{const K=T.stencilBuffer?r.DEPTH_STENCIL_ATTACHMENT:r.DEPTH_ATTACHMENT,Z=S.__webglDepthbuffer;r.bindRenderbuffer(r.RENDERBUFFER,Z),r.framebufferRenderbuffer(r.FRAMEBUFFER,K,r.RENDERBUFFER,Z)}e.bindFramebuffer(r.FRAMEBUFFER,null)}function Bt(T,S,k){const K=n.get(T);S!==void 0&&yt(K.__webglFramebuffer,T,T.texture,r.COLOR_ATTACHMENT0,r.TEXTURE_2D,0),k!==void 0&&Lt(T)}function ve(T){const S=T.texture,k=n.get(T),K=n.get(S);T.addEventListener("dispose",A);const Z=T.textures,q=T.isWebGLCubeRenderTarget===!0,Mt=Z.length>1;if(Mt||(K.__webglTexture===void 0&&(K.__webglTexture=r.createTexture()),K.__version=S.version,a.memory.textures++),q){k.__webglFramebuffer=[];for(let ot=0;ot<6;ot++)if(S.mipmaps&&S.mipmaps.length>0){k.__webglFramebuffer[ot]=[];for(let ft=0;ft<S.mipmaps.length;ft++)k.__webglFramebuffer[ot][ft]=r.createFramebuffer()}else k.__webglFramebuffer[ot]=r.createFramebuffer()}else{if(S.mipmaps&&S.mipmaps.length>0){k.__webglFramebuffer=[];for(let ot=0;ot<S.mipmaps.length;ot++)k.__webglFramebuffer[ot]=r.createFramebuffer()}else k.__webglFramebuffer=r.createFramebuffer();if(Mt)for(let ot=0,ft=Z.length;ot<ft;ot++){const Kt=n.get(Z[ot]);Kt.__webglTexture===void 0&&(Kt.__webglTexture=r.createTexture(),a.memory.textures++)}if(T.samples>0&&Wt(T)===!1){k.__webglMultisampledFramebuffer=r.createFramebuffer(),k.__webglColorRenderbuffer=[],e.bindFramebuffer(r.FRAMEBUFFER,k.__webglMultisampledFramebuffer);for(let ot=0;ot<Z.length;ot++){const ft=Z[ot];k.__webglColorRenderbuffer[ot]=r.createRenderbuffer(),r.bindRenderbuffer(r.RENDERBUFFER,k.__webglColorRenderbuffer[ot]);const Kt=s.convert(ft.format,ft.colorSpace),J=s.convert(ft.type),pt=y(ft.internalFormat,Kt,J,ft.colorSpace,T.isXRRenderTarget===!0),Et=Gt(T);r.renderbufferStorageMultisample(r.RENDERBUFFER,Et,pt,T.width,T.height),r.framebufferRenderbuffer(r.FRAMEBUFFER,r.COLOR_ATTACHMENT0+ot,r.RENDERBUFFER,k.__webglColorRenderbuffer[ot])}r.bindRenderbuffer(r.RENDERBUFFER,null),T.depthBuffer&&(k.__webglDepthRenderbuffer=r.createRenderbuffer(),at(k.__webglDepthRenderbuffer,T,!0)),e.bindFramebuffer(r.FRAMEBUFFER,null)}}if(q){e.bindTexture(r.TEXTURE_CUBE_MAP,K.__webglTexture),kt(r.TEXTURE_CUBE_MAP,S);for(let ot=0;ot<6;ot++)if(S.mipmaps&&S.mipmaps.length>0)for(let ft=0;ft<S.mipmaps.length;ft++)yt(k.__webglFramebuffer[ot][ft],T,S,r.COLOR_ATTACHMENT0,r.TEXTURE_CUBE_MAP_POSITIVE_X+ot,ft);else yt(k.__webglFramebuffer[ot],T,S,r.COLOR_ATTACHMENT0,r.TEXTURE_CUBE_MAP_POSITIVE_X+ot,0);g(S)&&p(r.TEXTURE_CUBE_MAP),e.unbindTexture()}else if(Mt){for(let ot=0,ft=Z.length;ot<ft;ot++){const Kt=Z[ot],J=n.get(Kt);e.bindTexture(r.TEXTURE_2D,J.__webglTexture),kt(r.TEXTURE_2D,Kt),yt(k.__webglFramebuffer,T,Kt,r.COLOR_ATTACHMENT0+ot,r.TEXTURE_2D,0),g(Kt)&&p(r.TEXTURE_2D)}e.unbindTexture()}else{let ot=r.TEXTURE_2D;if((T.isWebGL3DRenderTarget||T.isWebGLArrayRenderTarget)&&(ot=T.isWebGL3DRenderTarget?r.TEXTURE_3D:r.TEXTURE_2D_ARRAY),e.bindTexture(ot,K.__webglTexture),kt(ot,S),S.mipmaps&&S.mipmaps.length>0)for(let ft=0;ft<S.mipmaps.length;ft++)yt(k.__webglFramebuffer[ft],T,S,r.COLOR_ATTACHMENT0,ot,ft);else yt(k.__webglFramebuffer,T,S,r.COLOR_ATTACHMENT0,ot,0);g(S)&&p(ot),e.unbindTexture()}T.depthBuffer&&Lt(T)}function Yt(T){const S=T.textures;for(let k=0,K=S.length;k<K;k++){const Z=S[k];if(g(Z)){const q=x(T),Mt=n.get(Z).__webglTexture;e.bindTexture(q,Mt),p(q),e.unbindTexture()}}}const Se=[],O=[];function nn(T){if(T.samples>0){if(Wt(T)===!1){const S=T.textures,k=T.width,K=T.height;let Z=r.COLOR_BUFFER_BIT;const q=T.stencilBuffer?r.DEPTH_STENCIL_ATTACHMENT:r.DEPTH_ATTACHMENT,Mt=n.get(T),ot=S.length>1;if(ot)for(let ft=0;ft<S.length;ft++)e.bindFramebuffer(r.FRAMEBUFFER,Mt.__webglMultisampledFramebuffer),r.framebufferRenderbuffer(r.FRAMEBUFFER,r.COLOR_ATTACHMENT0+ft,r.RENDERBUFFER,null),e.bindFramebuffer(r.FRAMEBUFFER,Mt.__webglFramebuffer),r.framebufferTexture2D(r.DRAW_FRAMEBUFFER,r.COLOR_ATTACHMENT0+ft,r.TEXTURE_2D,null,0);e.bindFramebuffer(r.READ_FRAMEBUFFER,Mt.__webglMultisampledFramebuffer),e.bindFramebuffer(r.DRAW_FRAMEBUFFER,Mt.__webglFramebuffer);for(let ft=0;ft<S.length;ft++){if(T.resolveDepthBuffer&&(T.depthBuffer&&(Z|=r.DEPTH_BUFFER_BIT),T.stencilBuffer&&T.resolveStencilBuffer&&(Z|=r.STENCIL_BUFFER_BIT)),ot){r.framebufferRenderbuffer(r.READ_FRAMEBUFFER,r.COLOR_ATTACHMENT0,r.RENDERBUFFER,Mt.__webglColorRenderbuffer[ft]);const Kt=n.get(S[ft]).__webglTexture;r.framebufferTexture2D(r.DRAW_FRAMEBUFFER,r.COLOR_ATTACHMENT0,r.TEXTURE_2D,Kt,0)}r.blitFramebuffer(0,0,k,K,0,0,k,K,Z,r.NEAREST),l===!0&&(Se.length=0,O.length=0,Se.push(r.COLOR_ATTACHMENT0+ft),T.depthBuffer&&T.resolveDepthBuffer===!1&&(Se.push(q),O.push(q),r.invalidateFramebuffer(r.DRAW_FRAMEBUFFER,O)),r.invalidateFramebuffer(r.READ_FRAMEBUFFER,Se))}if(e.bindFramebuffer(r.READ_FRAMEBUFFER,null),e.bindFramebuffer(r.DRAW_FRAMEBUFFER,null),ot)for(let ft=0;ft<S.length;ft++){e.bindFramebuffer(r.FRAMEBUFFER,Mt.__webglMultisampledFramebuffer),r.framebufferRenderbuffer(r.FRAMEBUFFER,r.COLOR_ATTACHMENT0+ft,r.RENDERBUFFER,Mt.__webglColorRenderbuffer[ft]);const Kt=n.get(S[ft]).__webglTexture;e.bindFramebuffer(r.FRAMEBUFFER,Mt.__webglFramebuffer),r.framebufferTexture2D(r.DRAW_FRAMEBUFFER,r.COLOR_ATTACHMENT0+ft,r.TEXTURE_2D,Kt,0)}e.bindFramebuffer(r.DRAW_FRAMEBUFFER,Mt.__webglMultisampledFramebuffer)}else if(T.depthBuffer&&T.resolveDepthBuffer===!1&&l){const S=T.stencilBuffer?r.DEPTH_STENCIL_ATTACHMENT:r.DEPTH_ATTACHMENT;r.invalidateFramebuffer(r.DRAW_FRAMEBUFFER,[S])}}}function Gt(T){return Math.min(i.maxSamples,T.samples)}function Wt(T){const S=n.get(T);return T.samples>0&&t.has("WEBGL_multisampled_render_to_texture")===!0&&S.__useRenderToTexture!==!1}function Tt(T){const S=a.render.frame;h.get(T)!==S&&(h.set(T,S),T.update())}function fe(T,S){const k=T.colorSpace,K=T.format,Z=T.type;return T.isCompressedTexture===!0||T.isVideoTexture===!0||k!==qe&&k!==di&&(Ht.getTransfer(k)===se?(K!==un||Z!==Jn)&&console.warn("THREE.WebGLTextures: sRGB encoded textures have to use RGBAFormat and UnsignedByteType."):console.error("THREE.WebGLTextures: Unsupported texture color space:",k)),S}function wt(T){return typeof HTMLImageElement<"u"&&T instanceof HTMLImageElement?(c.width=T.naturalWidth||T.width,c.height=T.naturalHeight||T.height):typeof VideoFrame<"u"&&T instanceof VideoFrame?(c.width=T.displayWidth,c.height=T.displayHeight):(c.width=T.width,c.height=T.height),c}this.allocateTextureUnit=R,this.resetTextureUnits=z,this.setTexture2D=j,this.setTexture2DArray=X,this.setTexture3D=Q,this.setTextureCube=G,this.rebindTextures=Bt,this.setupRenderTarget=ve,this.updateRenderTargetMipmap=Yt,this.updateMultisampleRenderTarget=nn,this.setupDepthRenderbuffer=Lt,this.setupFrameBufferTexture=yt,this.useMultisampledRTT=Wt}function J0(r,t){function e(n,i=di){let s;const a=Ht.getTransfer(i);if(n===Jn)return r.UNSIGNED_BYTE;if(n===sl)return r.UNSIGNED_SHORT_4_4_4_4;if(n===rl)return r.UNSIGNED_SHORT_5_5_5_1;if(n===Hh)return r.UNSIGNED_INT_5_9_9_9_REV;if(n===Bh)return r.BYTE;if(n===zh)return r.SHORT;if(n===Ks)return r.UNSIGNED_SHORT;if(n===il)return r.INT;if(n===Ui)return r.UNSIGNED_INT;if(n===Sn)return r.FLOAT;if(n===Pn)return r.HALF_FLOAT;if(n===Vh)return r.ALPHA;if(n===Gh)return r.RGB;if(n===un)return r.RGBA;if(n===Wh)return r.LUMINANCE;if(n===Xh)return r.LUMINANCE_ALPHA;if(n===is)return r.DEPTH_COMPONENT;if(n===hs)return r.DEPTH_STENCIL;if(n===al)return r.RED;if(n===ol)return r.RED_INTEGER;if(n===qh)return r.RG;if(n===ll)return r.RG_INTEGER;if(n===cl)return r.RGBA_INTEGER;if(n===zr||n===Hr||n===Vr||n===Gr)if(a===se)if(s=t.get("WEBGL_compressed_texture_s3tc_srgb"),s!==null){if(n===zr)return s.COMPRESSED_SRGB_S3TC_DXT1_EXT;if(n===Hr)return s.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;if(n===Vr)return s.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;if(n===Gr)return s.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT}else return null;else if(s=t.get("WEBGL_compressed_texture_s3tc"),s!==null){if(n===zr)return s.COMPRESSED_RGB_S3TC_DXT1_EXT;if(n===Hr)return s.COMPRESSED_RGBA_S3TC_DXT1_EXT;if(n===Vr)return s.COMPRESSED_RGBA_S3TC_DXT3_EXT;if(n===Gr)return s.COMPRESSED_RGBA_S3TC_DXT5_EXT}else return null;if(n===po||n===mo||n===go||n===vo)if(s=t.get("WEBGL_compressed_texture_pvrtc"),s!==null){if(n===po)return s.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;if(n===mo)return s.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;if(n===go)return s.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;if(n===vo)return s.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG}else return null;if(n===_o||n===xo||n===yo)if(s=t.get("WEBGL_compressed_texture_etc"),s!==null){if(n===_o||n===xo)return a===se?s.COMPRESSED_SRGB8_ETC2:s.COMPRESSED_RGB8_ETC2;if(n===yo)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC:s.COMPRESSED_RGBA8_ETC2_EAC}else return null;if(n===Mo||n===bo||n===So||n===wo||n===To||n===Eo||n===Ao||n===Ro||n===Co||n===Po||n===Lo||n===Io||n===Do||n===No)if(s=t.get("WEBGL_compressed_texture_astc"),s!==null){if(n===Mo)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR:s.COMPRESSED_RGBA_ASTC_4x4_KHR;if(n===bo)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR:s.COMPRESSED_RGBA_ASTC_5x4_KHR;if(n===So)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR:s.COMPRESSED_RGBA_ASTC_5x5_KHR;if(n===wo)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR:s.COMPRESSED_RGBA_ASTC_6x5_KHR;if(n===To)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR:s.COMPRESSED_RGBA_ASTC_6x6_KHR;if(n===Eo)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR:s.COMPRESSED_RGBA_ASTC_8x5_KHR;if(n===Ao)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR:s.COMPRESSED_RGBA_ASTC_8x6_KHR;if(n===Ro)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR:s.COMPRESSED_RGBA_ASTC_8x8_KHR;if(n===Co)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR:s.COMPRESSED_RGBA_ASTC_10x5_KHR;if(n===Po)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR:s.COMPRESSED_RGBA_ASTC_10x6_KHR;if(n===Lo)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR:s.COMPRESSED_RGBA_ASTC_10x8_KHR;if(n===Io)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR:s.COMPRESSED_RGBA_ASTC_10x10_KHR;if(n===Do)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR:s.COMPRESSED_RGBA_ASTC_12x10_KHR;if(n===No)return a===se?s.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR:s.COMPRESSED_RGBA_ASTC_12x12_KHR}else return null;if(n===Wr||n===Uo||n===Fo)if(s=t.get("EXT_texture_compression_bptc"),s!==null){if(n===Wr)return a===se?s.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT:s.COMPRESSED_RGBA_BPTC_UNORM_EXT;if(n===Uo)return s.COMPRESSED_RGB_BPTC_SIGNED_FLOAT_EXT;if(n===Fo)return s.COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_EXT}else return null;if(n===Yh||n===Oo||n===ko||n===Bo)if(s=t.get("EXT_texture_compression_rgtc"),s!==null){if(n===Wr)return s.COMPRESSED_RED_RGTC1_EXT;if(n===Oo)return s.COMPRESSED_SIGNED_RED_RGTC1_EXT;if(n===ko)return s.COMPRESSED_RED_GREEN_RGTC2_EXT;if(n===Bo)return s.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT}else return null;return n===cs?r.UNSIGNED_INT_24_8:r[n]!==void 0?r[n]:null}return{convert:e}}class Q0 extends ze{constructor(t=[]){super(),this.isArrayCamera=!0,this.cameras=t}}class De extends he{constructor(){super(),this.isGroup=!0,this.type="Group"}}const tv={type:"move"};class za{constructor(){this._targetRay=null,this._grip=null,this._hand=null}getHandSpace(){return this._hand===null&&(this._hand=new De,this._hand.matrixAutoUpdate=!1,this._hand.visible=!1,this._hand.joints={},this._hand.inputState={pinching:!1}),this._hand}getTargetRaySpace(){return this._targetRay===null&&(this._targetRay=new De,this._targetRay.matrixAutoUpdate=!1,this._targetRay.visible=!1,this._targetRay.hasLinearVelocity=!1,this._targetRay.linearVelocity=new P,this._targetRay.hasAngularVelocity=!1,this._targetRay.angularVelocity=new P),this._targetRay}getGripSpace(){return this._grip===null&&(this._grip=new De,this._grip.matrixAutoUpdate=!1,this._grip.visible=!1,this._grip.hasLinearVelocity=!1,this._grip.linearVelocity=new P,this._grip.hasAngularVelocity=!1,this._grip.angularVelocity=new P),this._grip}dispatchEvent(t){return this._targetRay!==null&&this._targetRay.dispatchEvent(t),this._grip!==null&&this._grip.dispatchEvent(t),this._hand!==null&&this._hand.dispatchEvent(t),this}connect(t){if(t&&t.hand){const e=this._hand;if(e)for(const n of t.hand.values())this._getHandJoint(e,n)}return this.dispatchEvent({type:"connected",data:t}),this}disconnect(t){return this.dispatchEvent({type:"disconnected",data:t}),this._targetRay!==null&&(this._targetRay.visible=!1),this._grip!==null&&(this._grip.visible=!1),this._hand!==null&&(this._hand.visible=!1),this}update(t,e,n){let i=null,s=null,a=null;const o=this._targetRay,l=this._grip,c=this._hand;if(t&&e.session.visibilityState!=="visible-blurred"){if(c&&t.hand){a=!0;for(const v of t.hand.values()){const g=e.getJointPose(v,n),p=this._getHandJoint(c,v);g!==null&&(p.matrix.fromArray(g.transform.matrix),p.matrix.decompose(p.position,p.rotation,p.scale),p.matrixWorldNeedsUpdate=!0,p.jointRadius=g.radius),p.visible=g!==null}const h=c.joints["index-finger-tip"],u=c.joints["thumb-tip"],d=h.position.distanceTo(u.position),f=.02,m=.005;c.inputState.pinching&&d>f+m?(c.inputState.pinching=!1,this.dispatchEvent({type:"pinchend",handedness:t.handedness,target:this})):!c.inputState.pinching&&d<=f-m&&(c.inputState.pinching=!0,this.dispatchEvent({type:"pinchstart",handedness:t.handedness,target:this}))}else l!==null&&t.gripSpace&&(s=e.getPose(t.gripSpace,n),s!==null&&(l.matrix.fromArray(s.transform.matrix),l.matrix.decompose(l.position,l.rotation,l.scale),l.matrixWorldNeedsUpdate=!0,s.linearVelocity?(l.hasLinearVelocity=!0,l.linearVelocity.copy(s.linearVelocity)):l.hasLinearVelocity=!1,s.angularVelocity?(l.hasAngularVelocity=!0,l.angularVelocity.copy(s.angularVelocity)):l.hasAngularVelocity=!1));o!==null&&(i=e.getPose(t.targetRaySpace,n),i===null&&s!==null&&(i=s),i!==null&&(o.matrix.fromArray(i.transform.matrix),o.matrix.decompose(o.position,o.rotation,o.scale),o.matrixWorldNeedsUpdate=!0,i.linearVelocity?(o.hasLinearVelocity=!0,o.linearVelocity.copy(i.linearVelocity)):o.hasLinearVelocity=!1,i.angularVelocity?(o.hasAngularVelocity=!0,o.angularVelocity.copy(i.angularVelocity)):o.hasAngularVelocity=!1,this.dispatchEvent(tv)))}return o!==null&&(o.visible=i!==null),l!==null&&(l.visible=s!==null),c!==null&&(c.visible=a!==null),this}_getHandJoint(t,e){if(t.joints[e.jointName]===void 0){const n=new De;n.matrixAutoUpdate=!1,n.visible=!1,t.joints[e.jointName]=n,t.add(n)}return t.joints[e.jointName]}}const ev=`
void main() {

	gl_Position = vec4( position, 1.0 );

}`,nv=`
uniform sampler2DArray depthColor;
uniform float depthWidth;
uniform float depthHeight;

void main() {

	vec2 coord = vec2( gl_FragCoord.x / depthWidth, gl_FragCoord.y / depthHeight );

	if ( coord.x >= 1.0 ) {

		gl_FragDepth = texture( depthColor, vec3( coord.x - 1.0, coord.y, 1 ) ).r;

	} else {

		gl_FragDepth = texture( depthColor, vec3( coord.x, coord.y, 0 ) ).r;

	}

}`;class iv{constructor(){this.texture=null,this.mesh=null,this.depthNear=0,this.depthFar=0}init(t,e,n){if(this.texture===null){const i=new Ce,s=t.properties.get(i);s.__webglTexture=e.texture,(e.depthNear!=n.depthNear||e.depthFar!=n.depthFar)&&(this.depthNear=e.depthNear,this.depthFar=e.depthFar),this.texture=i}}getMesh(t){if(this.texture!==null&&this.mesh===null){const e=t.cameras[0].viewport,n=new Te({vertexShader:ev,fragmentShader:nv,uniforms:{depthColor:{value:this.texture},depthWidth:{value:e.z},depthHeight:{value:e.w}}});this.mesh=new Rt(new We(20,20),n)}return this.mesh}reset(){this.texture=null,this.mesh=null}getDepthTexture(){return this.texture}}class sv extends _s{constructor(t,e){super();const n=this;let i=null,s=1,a=null,o="local-floor",l=1,c=null,h=null,u=null,d=null,f=null,m=null;const v=new iv,g=e.getContextAttributes();let p=null,x=null;const y=[],_=[],I=new nt;let E=null;const A=new ze;A.viewport=new Qt;const C=new ze;C.viewport=new Qt;const b=[A,C],M=new Q0;let L=null,z=null;this.cameraAutoUpdate=!0,this.enabled=!1,this.isPresenting=!1,this.getController=function(Y){let et=y[Y];return et===void 0&&(et=new za,y[Y]=et),et.getTargetRaySpace()},this.getControllerGrip=function(Y){let et=y[Y];return et===void 0&&(et=new za,y[Y]=et),et.getGripSpace()},this.getHand=function(Y){let et=y[Y];return et===void 0&&(et=new za,y[Y]=et),et.getHandSpace()};function R(Y){const et=_.indexOf(Y.inputSource);if(et===-1)return;const yt=y[et];yt!==void 0&&(yt.update(Y.inputSource,Y.frame,c||a),yt.dispatchEvent({type:Y.type,data:Y.inputSource}))}function B(){i.removeEventListener("select",R),i.removeEventListener("selectstart",R),i.removeEventListener("selectend",R),i.removeEventListener("squeeze",R),i.removeEventListener("squeezestart",R),i.removeEventListener("squeezeend",R),i.removeEventListener("end",B),i.removeEventListener("inputsourceschange",j);for(let Y=0;Y<y.length;Y++){const et=_[Y];et!==null&&(_[Y]=null,y[Y].disconnect(et))}L=null,z=null,v.reset(),t.setRenderTarget(p),f=null,d=null,u=null,i=null,x=null,ce.stop(),n.isPresenting=!1,t.setPixelRatio(E),t.setSize(I.width,I.height,!1),n.dispatchEvent({type:"sessionend"})}this.setFramebufferScaleFactor=function(Y){s=Y,n.isPresenting===!0&&console.warn("THREE.WebXRManager: Cannot change framebuffer scale while presenting.")},this.setReferenceSpaceType=function(Y){o=Y,n.isPresenting===!0&&console.warn("THREE.WebXRManager: Cannot change reference space type while presenting.")},this.getReferenceSpace=function(){return c||a},this.setReferenceSpace=function(Y){c=Y},this.getBaseLayer=function(){return d!==null?d:f},this.getBinding=function(){return u},this.getFrame=function(){return m},this.getSession=function(){return i},this.setSession=async function(Y){if(i=Y,i!==null){if(p=t.getRenderTarget(),i.addEventListener("select",R),i.addEventListener("selectstart",R),i.addEventListener("selectend",R),i.addEventListener("squeeze",R),i.addEventListener("squeezestart",R),i.addEventListener("squeezeend",R),i.addEventListener("end",B),i.addEventListener("inputsourceschange",j),g.xrCompatible!==!0&&await e.makeXRCompatible(),E=t.getPixelRatio(),t.getSize(I),i.renderState.layers===void 0){const et={antialias:g.antialias,alpha:!0,depth:g.depth,stencil:g.stencil,framebufferScaleFactor:s};f=new XRWebGLLayer(i,e,et),i.updateRenderState({baseLayer:f}),t.setPixelRatio(1),t.setSize(f.framebufferWidth,f.framebufferHeight,!1),x=new fn(f.framebufferWidth,f.framebufferHeight,{format:un,type:Jn,colorSpace:t.outputColorSpace,stencilBuffer:g.stencil})}else{let et=null,yt=null,at=null;g.depth&&(at=g.stencil?e.DEPTH24_STENCIL8:e.DEPTH_COMPONENT24,et=g.stencil?hs:is,yt=g.stencil?cs:Ui);const At={colorFormat:e.RGBA8,depthFormat:at,scaleFactor:s};u=new XRWebGLBinding(i,e),d=u.createProjectionLayer(At),i.updateRenderState({layers:[d]}),t.setPixelRatio(1),t.setSize(d.textureWidth,d.textureHeight,!1),x=new fn(d.textureWidth,d.textureHeight,{format:un,type:Jn,depthTexture:new lu(d.textureWidth,d.textureHeight,yt,void 0,void 0,void 0,void 0,void 0,void 0,et),stencilBuffer:g.stencil,colorSpace:t.outputColorSpace,samples:g.antialias?4:0,resolveDepthBuffer:d.ignoreDepthValues===!1})}x.isXRRenderTarget=!0,this.setFoveation(l),c=null,a=await i.requestReferenceSpace(o),ce.setContext(i),ce.start(),n.isPresenting=!0,n.dispatchEvent({type:"sessionstart"})}},this.getEnvironmentBlendMode=function(){if(i!==null)return i.environmentBlendMode},this.getDepthTexture=function(){return v.getDepthTexture()};function j(Y){for(let et=0;et<Y.removed.length;et++){const yt=Y.removed[et],at=_.indexOf(yt);at>=0&&(_[at]=null,y[at].disconnect(yt))}for(let et=0;et<Y.added.length;et++){const yt=Y.added[et];let at=_.indexOf(yt);if(at===-1){for(let Lt=0;Lt<y.length;Lt++)if(Lt>=_.length){_.push(yt),at=Lt;break}else if(_[Lt]===null){_[Lt]=yt,at=Lt;break}if(at===-1)break}const At=y[at];At&&At.connect(yt)}}const X=new P,Q=new P;function G(Y,et,yt){X.setFromMatrixPosition(et.matrixWorld),Q.setFromMatrixPosition(yt.matrixWorld);const at=X.distanceTo(Q),At=et.projectionMatrix.elements,Lt=yt.projectionMatrix.elements,Bt=At[14]/(At[10]-1),ve=At[14]/(At[10]+1),Yt=(At[9]+1)/At[5],Se=(At[9]-1)/At[5],O=(At[8]-1)/At[0],nn=(Lt[8]+1)/Lt[0],Gt=Bt*O,Wt=Bt*nn,Tt=at/(-O+nn),fe=Tt*-O;if(et.matrixWorld.decompose(Y.position,Y.quaternion,Y.scale),Y.translateX(fe),Y.translateZ(Tt),Y.matrixWorld.compose(Y.position,Y.quaternion,Y.scale),Y.matrixWorldInverse.copy(Y.matrixWorld).invert(),At[10]===-1)Y.projectionMatrix.copy(et.projectionMatrix),Y.projectionMatrixInverse.copy(et.projectionMatrixInverse);else{const wt=Bt+Tt,T=ve+Tt,S=Gt-fe,k=Wt+(at-fe),K=Yt*ve/T*wt,Z=Se*ve/T*wt;Y.projectionMatrix.makePerspective(S,k,K,Z,wt,T),Y.projectionMatrixInverse.copy(Y.projectionMatrix).invert()}}function it(Y,et){et===null?Y.matrixWorld.copy(Y.matrix):Y.matrixWorld.multiplyMatrices(et.matrixWorld,Y.matrix),Y.matrixWorldInverse.copy(Y.matrixWorld).invert()}this.updateCamera=function(Y){if(i===null)return;let et=Y.near,yt=Y.far;v.texture!==null&&(v.depthNear>0&&(et=v.depthNear),v.depthFar>0&&(yt=v.depthFar)),M.near=C.near=A.near=et,M.far=C.far=A.far=yt,(L!==M.near||z!==M.far)&&(i.updateRenderState({depthNear:M.near,depthFar:M.far}),L=M.near,z=M.far),A.layers.mask=Y.layers.mask|2,C.layers.mask=Y.layers.mask|4,M.layers.mask=A.layers.mask|C.layers.mask;const at=Y.parent,At=M.cameras;it(M,at);for(let Lt=0;Lt<At.length;Lt++)it(At[Lt],at);At.length===2?G(M,A,C):M.projectionMatrix.copy(A.projectionMatrix),lt(Y,M,at)};function lt(Y,et,yt){yt===null?Y.matrix.copy(et.matrixWorld):(Y.matrix.copy(yt.matrixWorld),Y.matrix.invert(),Y.matrix.multiply(et.matrixWorld)),Y.matrix.decompose(Y.position,Y.quaternion,Y.scale),Y.updateMatrixWorld(!0),Y.projectionMatrix.copy(et.projectionMatrix),Y.projectionMatrixInverse.copy(et.projectionMatrixInverse),Y.isPerspectiveCamera&&(Y.fov=us*2*Math.atan(1/Y.projectionMatrix.elements[5]),Y.zoom=1)}this.getCamera=function(){return M},this.getFoveation=function(){if(!(d===null&&f===null))return l},this.setFoveation=function(Y){l=Y,d!==null&&(d.fixedFoveation=Y),f!==null&&f.fixedFoveation!==void 0&&(f.fixedFoveation=Y)},this.hasDepthSensing=function(){return v.texture!==null},this.getDepthSensingMesh=function(){return v.getMesh(M)};let St=null;function kt(Y,et){if(h=et.getViewerPose(c||a),m=et,h!==null){const yt=h.views;f!==null&&(t.setRenderTargetFramebuffer(x,f.framebuffer),t.setRenderTarget(x));let at=!1;yt.length!==M.cameras.length&&(M.cameras.length=0,at=!0);for(let Lt=0;Lt<yt.length;Lt++){const Bt=yt[Lt];let ve=null;if(f!==null)ve=f.getViewport(Bt);else{const Se=u.getViewSubImage(d,Bt);ve=Se.viewport,Lt===0&&(t.setRenderTargetTextures(x,Se.colorTexture,d.ignoreDepthValues?void 0:Se.depthStencilTexture),t.setRenderTarget(x))}let Yt=b[Lt];Yt===void 0&&(Yt=new ze,Yt.layers.enable(Lt),Yt.viewport=new Qt,b[Lt]=Yt),Yt.matrix.fromArray(Bt.transform.matrix),Yt.matrix.decompose(Yt.position,Yt.quaternion,Yt.scale),Yt.projectionMatrix.fromArray(Bt.projectionMatrix),Yt.projectionMatrixInverse.copy(Yt.projectionMatrix).invert(),Yt.viewport.set(ve.x,ve.y,ve.width,ve.height),Lt===0&&(M.matrix.copy(Yt.matrix),M.matrix.decompose(M.position,M.quaternion,M.scale)),at===!0&&M.cameras.push(Yt)}const At=i.enabledFeatures;if(At&&At.includes("depth-sensing")){const Lt=u.getDepthInformation(yt[0]);Lt&&Lt.isValid&&Lt.texture&&v.init(t,Lt,i.renderState)}}for(let yt=0;yt<y.length;yt++){const at=_[yt],At=y[yt];at!==null&&At!==void 0&&At.update(at,et,c||a)}St&&St(Y,et),et.detectedPlanes&&n.dispatchEvent({type:"planesdetected",data:et}),m=null}const ce=new ou;ce.setAnimationLoop(kt),this.setAnimationLoop=function(Y){St=Y},this.dispose=function(){}}}const Ei=new En,rv=new It;function av(r,t){function e(g,p){g.matrixAutoUpdate===!0&&g.updateMatrix(),p.value.copy(g.matrix)}function n(g,p){p.color.getRGB(g.fogColor.value,su(r)),p.isFog?(g.fogNear.value=p.near,g.fogFar.value=p.far):p.isFogExp2&&(g.fogDensity.value=p.density)}function i(g,p,x,y,_){p.isMeshBasicMaterial||p.isMeshLambertMaterial?s(g,p):p.isMeshToonMaterial?(s(g,p),u(g,p)):p.isMeshPhongMaterial?(s(g,p),h(g,p)):p.isMeshStandardMaterial?(s(g,p),d(g,p),p.isMeshPhysicalMaterial&&f(g,p,_)):p.isMeshMatcapMaterial?(s(g,p),m(g,p)):p.isMeshDepthMaterial?s(g,p):p.isMeshDistanceMaterial?(s(g,p),v(g,p)):p.isMeshNormalMaterial?s(g,p):p.isLineBasicMaterial?(a(g,p),p.isLineDashedMaterial&&o(g,p)):p.isPointsMaterial?l(g,p,x,y):p.isSpriteMaterial?c(g,p):p.isShadowMaterial?(g.color.value.copy(p.color),g.opacity.value=p.opacity):p.isShaderMaterial&&(p.uniformsNeedUpdate=!1)}function s(g,p){g.opacity.value=p.opacity,p.color&&g.diffuse.value.copy(p.color),p.emissive&&g.emissive.value.copy(p.emissive).multiplyScalar(p.emissiveIntensity),p.map&&(g.map.value=p.map,e(p.map,g.mapTransform)),p.alphaMap&&(g.alphaMap.value=p.alphaMap,e(p.alphaMap,g.alphaMapTransform)),p.bumpMap&&(g.bumpMap.value=p.bumpMap,e(p.bumpMap,g.bumpMapTransform),g.bumpScale.value=p.bumpScale,p.side===$e&&(g.bumpScale.value*=-1)),p.normalMap&&(g.normalMap.value=p.normalMap,e(p.normalMap,g.normalMapTransform),g.normalScale.value.copy(p.normalScale),p.side===$e&&g.normalScale.value.negate()),p.displacementMap&&(g.displacementMap.value=p.displacementMap,e(p.displacementMap,g.displacementMapTransform),g.displacementScale.value=p.displacementScale,g.displacementBias.value=p.displacementBias),p.emissiveMap&&(g.emissiveMap.value=p.emissiveMap,e(p.emissiveMap,g.emissiveMapTransform)),p.specularMap&&(g.specularMap.value=p.specularMap,e(p.specularMap,g.specularMapTransform)),p.alphaTest>0&&(g.alphaTest.value=p.alphaTest);const x=t.get(p),y=x.envMap,_=x.envMapRotation;y&&(g.envMap.value=y,Ei.copy(_),Ei.x*=-1,Ei.y*=-1,Ei.z*=-1,y.isCubeTexture&&y.isRenderTargetTexture===!1&&(Ei.y*=-1,Ei.z*=-1),g.envMapRotation.value.setFromMatrix4(rv.makeRotationFromEuler(Ei)),g.flipEnvMap.value=y.isCubeTexture&&y.isRenderTargetTexture===!1?-1:1,g.reflectivity.value=p.reflectivity,g.ior.value=p.ior,g.refractionRatio.value=p.refractionRatio),p.lightMap&&(g.lightMap.value=p.lightMap,g.lightMapIntensity.value=p.lightMapIntensity,e(p.lightMap,g.lightMapTransform)),p.aoMap&&(g.aoMap.value=p.aoMap,g.aoMapIntensity.value=p.aoMapIntensity,e(p.aoMap,g.aoMapTransform))}function a(g,p){g.diffuse.value.copy(p.color),g.opacity.value=p.opacity,p.map&&(g.map.value=p.map,e(p.map,g.mapTransform))}function o(g,p){g.dashSize.value=p.dashSize,g.totalSize.value=p.dashSize+p.gapSize,g.scale.value=p.scale}function l(g,p,x,y){g.diffuse.value.copy(p.color),g.opacity.value=p.opacity,g.size.value=p.size*x,g.scale.value=y*.5,p.map&&(g.map.value=p.map,e(p.map,g.uvTransform)),p.alphaMap&&(g.alphaMap.value=p.alphaMap,e(p.alphaMap,g.alphaMapTransform)),p.alphaTest>0&&(g.alphaTest.value=p.alphaTest)}function c(g,p){g.diffuse.value.copy(p.color),g.opacity.value=p.opacity,g.rotation.value=p.rotation,p.map&&(g.map.value=p.map,e(p.map,g.mapTransform)),p.alphaMap&&(g.alphaMap.value=p.alphaMap,e(p.alphaMap,g.alphaMapTransform)),p.alphaTest>0&&(g.alphaTest.value=p.alphaTest)}function h(g,p){g.specular.value.copy(p.specular),g.shininess.value=Math.max(p.shininess,1e-4)}function u(g,p){p.gradientMap&&(g.gradientMap.value=p.gradientMap)}function d(g,p){g.metalness.value=p.metalness,p.metalnessMap&&(g.metalnessMap.value=p.metalnessMap,e(p.metalnessMap,g.metalnessMapTransform)),g.roughness.value=p.roughness,p.roughnessMap&&(g.roughnessMap.value=p.roughnessMap,e(p.roughnessMap,g.roughnessMapTransform)),p.envMap&&(g.envMapIntensity.value=p.envMapIntensity)}function f(g,p,x){g.ior.value=p.ior,p.sheen>0&&(g.sheenColor.value.copy(p.sheenColor).multiplyScalar(p.sheen),g.sheenRoughness.value=p.sheenRoughness,p.sheenColorMap&&(g.sheenColorMap.value=p.sheenColorMap,e(p.sheenColorMap,g.sheenColorMapTransform)),p.sheenRoughnessMap&&(g.sheenRoughnessMap.value=p.sheenRoughnessMap,e(p.sheenRoughnessMap,g.sheenRoughnessMapTransform))),p.clearcoat>0&&(g.clearcoat.value=p.clearcoat,g.clearcoatRoughness.value=p.clearcoatRoughness,p.clearcoatMap&&(g.clearcoatMap.value=p.clearcoatMap,e(p.clearcoatMap,g.clearcoatMapTransform)),p.clearcoatRoughnessMap&&(g.clearcoatRoughnessMap.value=p.clearcoatRoughnessMap,e(p.clearcoatRoughnessMap,g.clearcoatRoughnessMapTransform)),p.clearcoatNormalMap&&(g.clearcoatNormalMap.value=p.clearcoatNormalMap,e(p.clearcoatNormalMap,g.clearcoatNormalMapTransform),g.clearcoatNormalScale.value.copy(p.clearcoatNormalScale),p.side===$e&&g.clearcoatNormalScale.value.negate())),p.dispersion>0&&(g.dispersion.value=p.dispersion),p.iridescence>0&&(g.iridescence.value=p.iridescence,g.iridescenceIOR.value=p.iridescenceIOR,g.iridescenceThicknessMinimum.value=p.iridescenceThicknessRange[0],g.iridescenceThicknessMaximum.value=p.iridescenceThicknessRange[1],p.iridescenceMap&&(g.iridescenceMap.value=p.iridescenceMap,e(p.iridescenceMap,g.iridescenceMapTransform)),p.iridescenceThicknessMap&&(g.iridescenceThicknessMap.value=p.iridescenceThicknessMap,e(p.iridescenceThicknessMap,g.iridescenceThicknessMapTransform))),p.transmission>0&&(g.transmission.value=p.transmission,g.transmissionSamplerMap.value=x.texture,g.transmissionSamplerSize.value.set(x.width,x.height),p.transmissionMap&&(g.transmissionMap.value=p.transmissionMap,e(p.transmissionMap,g.transmissionMapTransform)),g.thickness.value=p.thickness,p.thicknessMap&&(g.thicknessMap.value=p.thicknessMap,e(p.thicknessMap,g.thicknessMapTransform)),g.attenuationDistance.value=p.attenuationDistance,g.attenuationColor.value.copy(p.attenuationColor)),p.anisotropy>0&&(g.anisotropyVector.value.set(p.anisotropy*Math.cos(p.anisotropyRotation),p.anisotropy*Math.sin(p.anisotropyRotation)),p.anisotropyMap&&(g.anisotropyMap.value=p.anisotropyMap,e(p.anisotropyMap,g.anisotropyMapTransform))),g.specularIntensity.value=p.specularIntensity,g.specularColor.value.copy(p.specularColor),p.specularColorMap&&(g.specularColorMap.value=p.specularColorMap,e(p.specularColorMap,g.specularColorMapTransform)),p.specularIntensityMap&&(g.specularIntensityMap.value=p.specularIntensityMap,e(p.specularIntensityMap,g.specularIntensityMapTransform))}function m(g,p){p.matcap&&(g.matcap.value=p.matcap)}function v(g,p){const x=t.get(p).light;g.referencePosition.value.setFromMatrixPosition(x.matrixWorld),g.nearDistance.value=x.shadow.camera.near,g.farDistance.value=x.shadow.camera.far}return{refreshFogUniforms:n,refreshMaterialUniforms:i}}function ov(r,t,e,n){let i={},s={},a=[];const o=r.getParameter(r.MAX_UNIFORM_BUFFER_BINDINGS);function l(x,y){const _=y.program;n.uniformBlockBinding(x,_)}function c(x,y){let _=i[x.id];_===void 0&&(m(x),_=h(x),i[x.id]=_,x.addEventListener("dispose",g));const I=y.program;n.updateUBOMapping(x,I);const E=t.render.frame;s[x.id]!==E&&(d(x),s[x.id]=E)}function h(x){const y=u();x.__bindingPointIndex=y;const _=r.createBuffer(),I=x.__size,E=x.usage;return r.bindBuffer(r.UNIFORM_BUFFER,_),r.bufferData(r.UNIFORM_BUFFER,I,E),r.bindBuffer(r.UNIFORM_BUFFER,null),r.bindBufferBase(r.UNIFORM_BUFFER,y,_),_}function u(){for(let x=0;x<o;x++)if(a.indexOf(x)===-1)return a.push(x),x;return console.error("THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached."),0}function d(x){const y=i[x.id],_=x.uniforms,I=x.__cache;r.bindBuffer(r.UNIFORM_BUFFER,y);for(let E=0,A=_.length;E<A;E++){const C=Array.isArray(_[E])?_[E]:[_[E]];for(let b=0,M=C.length;b<M;b++){const L=C[b];if(f(L,E,b,I)===!0){const z=L.__offset,R=Array.isArray(L.value)?L.value:[L.value];let B=0;for(let j=0;j<R.length;j++){const X=R[j],Q=v(X);typeof X=="number"||typeof X=="boolean"?(L.__data[0]=X,r.bufferSubData(r.UNIFORM_BUFFER,z+B,L.__data)):X.isMatrix3?(L.__data[0]=X.elements[0],L.__data[1]=X.elements[1],L.__data[2]=X.elements[2],L.__data[3]=0,L.__data[4]=X.elements[3],L.__data[5]=X.elements[4],L.__data[6]=X.elements[5],L.__data[7]=0,L.__data[8]=X.elements[6],L.__data[9]=X.elements[7],L.__data[10]=X.elements[8],L.__data[11]=0):(X.toArray(L.__data,B),B+=Q.storage/Float32Array.BYTES_PER_ELEMENT)}r.bufferSubData(r.UNIFORM_BUFFER,z,L.__data)}}}r.bindBuffer(r.UNIFORM_BUFFER,null)}function f(x,y,_,I){const E=x.value,A=y+"_"+_;if(I[A]===void 0)return typeof E=="number"||typeof E=="boolean"?I[A]=E:I[A]=E.clone(),!0;{const C=I[A];if(typeof E=="number"||typeof E=="boolean"){if(C!==E)return I[A]=E,!0}else if(C.equals(E)===!1)return C.copy(E),!0}return!1}function m(x){const y=x.uniforms;let _=0;const I=16;for(let A=0,C=y.length;A<C;A++){const b=Array.isArray(y[A])?y[A]:[y[A]];for(let M=0,L=b.length;M<L;M++){const z=b[M],R=Array.isArray(z.value)?z.value:[z.value];for(let B=0,j=R.length;B<j;B++){const X=R[B],Q=v(X),G=_%I,it=G%Q.boundary,lt=G+it;_+=it,lt!==0&&I-lt<Q.storage&&(_+=I-lt),z.__data=new Float32Array(Q.storage/Float32Array.BYTES_PER_ELEMENT),z.__offset=_,_+=Q.storage}}}const E=_%I;return E>0&&(_+=I-E),x.__size=_,x.__cache={},this}function v(x){const y={boundary:0,storage:0};return typeof x=="number"||typeof x=="boolean"?(y.boundary=4,y.storage=4):x.isVector2?(y.boundary=8,y.storage=8):x.isVector3||x.isColor?(y.boundary=16,y.storage=12):x.isVector4?(y.boundary=16,y.storage=16):x.isMatrix3?(y.boundary=48,y.storage=48):x.isMatrix4?(y.boundary=64,y.storage=64):x.isTexture?console.warn("THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group."):console.warn("THREE.WebGLRenderer: Unsupported uniform value type.",x),y}function g(x){const y=x.target;y.removeEventListener("dispose",g);const _=a.indexOf(y.__bindingPointIndex);a.splice(_,1),r.deleteBuffer(i[y.id]),delete i[y.id],delete s[y.id]}function p(){for(const x in i)r.deleteBuffer(i[x]);a=[],i={},s={}}return{bind:l,update:c,dispose:p}}class lv{constructor(t={}){const{canvas:e=jd(),context:n=null,depth:i=!0,stencil:s=!1,alpha:a=!1,antialias:o=!1,premultipliedAlpha:l=!0,preserveDrawingBuffer:c=!1,powerPreference:h="default",failIfMajorPerformanceCaveat:u=!1,reverseDepthBuffer:d=!1}=t;this.isWebGLRenderer=!0;let f;if(n!==null){if(typeof WebGLRenderingContext<"u"&&n instanceof WebGLRenderingContext)throw new Error("THREE.WebGLRenderer: WebGL 1 is not supported since r163.");f=n.getContextAttributes().alpha}else f=a;const m=new Uint32Array(4),v=new Int32Array(4);let g=null,p=null;const x=[],y=[];this.domElement=e,this.debug={checkShaderErrors:!0,onShaderError:null},this.autoClear=!0,this.autoClearColor=!0,this.autoClearDepth=!0,this.autoClearStencil=!0,this.sortObjects=!0,this.clippingPlanes=[],this.localClippingEnabled=!1,this._outputColorSpace=be,this.toneMapping=gi,this.toneMappingExposure=1;const _=this;let I=!1,E=0,A=0,C=null,b=-1,M=null;const L=new Qt,z=new Qt;let R=null;const B=new dt(0);let j=0,X=e.width,Q=e.height,G=1,it=null,lt=null;const St=new Qt(0,0,X,Q),kt=new Qt(0,0,X,Q);let ce=!1;const Y=new dl;let et=!1,yt=!1;const at=new It,At=new It,Lt=new P,Bt=new Qt,ve={background:null,fog:null,environment:null,overrideMaterial:null,isScene:!0};let Yt=!1;function Se(){return C===null?G:1}let O=n;function nn(w,U){return e.getContext(w,U)}try{const w={alpha:!0,depth:i,stencil:s,antialias:o,premultipliedAlpha:l,preserveDrawingBuffer:c,powerPreference:h,failIfMajorPerformanceCaveat:u};if("setAttribute"in e&&e.setAttribute("data-engine",`three.js r${tl}`),e.addEventListener("webglcontextlost",$,!1),e.addEventListener("webglcontextrestored",ut,!1),e.addEventListener("webglcontextcreationerror",ct,!1),O===null){const U="webgl2";if(O=nn(U,w),O===null)throw nn(U)?new Error("Error creating WebGL context with your selected attributes."):new Error("Error creating WebGL context.")}}catch(w){throw console.error("THREE.WebGLRenderer: "+w.message),w}let Gt,Wt,Tt,fe,wt,T,S,k,K,Z,q,Mt,ot,ft,Kt,J,pt,Et,Ct,mt,Xt,Ft,ue,N;function rt(){Gt=new fg(O),Gt.init(),Ft=new J0(O,Gt),Wt=new og(O,Gt,t,Ft),Tt=new $0(O,Gt),Wt.reverseDepthBuffer&&d&&Tt.buffers.depth.setReversed(!0),fe=new gg(O),wt=new N0,T=new Z0(O,Gt,Tt,wt,Wt,Ft,fe),S=new cg(_),k=new dg(_),K=new Sf(O),ue=new rg(O,K),Z=new pg(O,K,fe,ue),q=new _g(O,Z,K,fe),Ct=new vg(O,Wt,T),J=new lg(wt),Mt=new D0(_,S,k,Gt,Wt,ue,J),ot=new av(_,wt),ft=new F0,Kt=new V0(Gt),Et=new sg(_,S,k,Tt,q,f,l),pt=new Y0(_,q,Wt),N=new ov(O,fe,Wt,Tt),mt=new ag(O,Gt,fe),Xt=new mg(O,Gt,fe),fe.programs=Mt.programs,_.capabilities=Wt,_.extensions=Gt,_.properties=wt,_.renderLists=ft,_.shadowMap=pt,_.state=Tt,_.info=fe}rt();const W=new sv(_,O);this.xr=W,this.getContext=function(){return O},this.getContextAttributes=function(){return O.getContextAttributes()},this.forceContextLoss=function(){const w=Gt.get("WEBGL_lose_context");w&&w.loseContext()},this.forceContextRestore=function(){const w=Gt.get("WEBGL_lose_context");w&&w.restoreContext()},this.getPixelRatio=function(){return G},this.setPixelRatio=function(w){w!==void 0&&(G=w,this.setSize(X,Q,!1))},this.getSize=function(w){return w.set(X,Q)},this.setSize=function(w,U,H=!0){if(W.isPresenting){console.warn("THREE.WebGLRenderer: Can't change size while VR device is presenting.");return}X=w,Q=U,e.width=Math.floor(w*G),e.height=Math.floor(U*G),H===!0&&(e.style.width=w+"px",e.style.height=U+"px"),this.setViewport(0,0,w,U)},this.getDrawingBufferSize=function(w){return w.set(X*G,Q*G).floor()},this.setDrawingBufferSize=function(w,U,H){X=w,Q=U,G=H,e.width=Math.floor(w*H),e.height=Math.floor(U*H),this.setViewport(0,0,w,U)},this.getCurrentViewport=function(w){return w.copy(L)},this.getViewport=function(w){return w.copy(St)},this.setViewport=function(w,U,H,V){w.isVector4?St.set(w.x,w.y,w.z,w.w):St.set(w,U,H,V),Tt.viewport(L.copy(St).multiplyScalar(G).round())},this.getScissor=function(w){return w.copy(kt)},this.setScissor=function(w,U,H,V){w.isVector4?kt.set(w.x,w.y,w.z,w.w):kt.set(w,U,H,V),Tt.scissor(z.copy(kt).multiplyScalar(G).round())},this.getScissorTest=function(){return ce},this.setScissorTest=function(w){Tt.setScissorTest(ce=w)},this.setOpaqueSort=function(w){it=w},this.setTransparentSort=function(w){lt=w},this.getClearColor=function(w){return w.copy(Et.getClearColor())},this.setClearColor=function(){Et.setClearColor.apply(Et,arguments)},this.getClearAlpha=function(){return Et.getClearAlpha()},this.setClearAlpha=function(){Et.setClearAlpha.apply(Et,arguments)},this.clear=function(w=!0,U=!0,H=!0){let V=0;if(w){let F=!1;if(C!==null){const tt=C.texture.format;F=tt===cl||tt===ll||tt===ol}if(F){const tt=C.texture.type,ht=tt===Jn||tt===Ui||tt===Ks||tt===cs||tt===sl||tt===rl,gt=Et.getClearColor(),vt=Et.getClearAlpha(),Pt=gt.r,Nt=gt.g,_t=gt.b;ht?(m[0]=Pt,m[1]=Nt,m[2]=_t,m[3]=vt,O.clearBufferuiv(O.COLOR,0,m)):(v[0]=Pt,v[1]=Nt,v[2]=_t,v[3]=vt,O.clearBufferiv(O.COLOR,0,v))}else V|=O.COLOR_BUFFER_BIT}U&&(V|=O.DEPTH_BUFFER_BIT),H&&(V|=O.STENCIL_BUFFER_BIT,this.state.buffers.stencil.setMask(4294967295)),O.clear(V)},this.clearColor=function(){this.clear(!0,!1,!1)},this.clearDepth=function(){this.clear(!1,!0,!1)},this.clearStencil=function(){this.clear(!1,!1,!0)},this.dispose=function(){e.removeEventListener("webglcontextlost",$,!1),e.removeEventListener("webglcontextrestored",ut,!1),e.removeEventListener("webglcontextcreationerror",ct,!1),ft.dispose(),Kt.dispose(),wt.dispose(),S.dispose(),k.dispose(),q.dispose(),ue.dispose(),N.dispose(),Mt.dispose(),W.dispose(),W.removeEventListener("sessionstart",Pl),W.removeEventListener("sessionend",Ll),yi.stop()};function $(w){w.preventDefault(),console.log("THREE.WebGLRenderer: Context Lost."),I=!0}function ut(){console.log("THREE.WebGLRenderer: Context Restored."),I=!1;const w=fe.autoReset,U=pt.enabled,H=pt.autoUpdate,V=pt.needsUpdate,F=pt.type;rt(),fe.autoReset=w,pt.enabled=U,pt.autoUpdate=H,pt.needsUpdate=V,pt.type=F}function ct(w){console.error("THREE.WebGLRenderer: A WebGL context could not be created. Reason: ",w.statusMessage)}function Dt(w){const U=w.target;U.removeEventListener("dispose",Dt),Me(U)}function Me(w){Fe(w),wt.remove(w)}function Fe(w){const U=wt.get(w).programs;U!==void 0&&(U.forEach(function(H){Mt.releaseProgram(H)}),w.isShaderMaterial&&Mt.releaseShaderCache(w))}this.renderBufferDirect=function(w,U,H,V,F,tt){U===null&&(U=ve);const ht=F.isMesh&&F.matrixWorld.determinant()<0,gt=Ku(w,U,H,V,F);Tt.setMaterial(V,ht);let vt=H.index,Pt=1;if(V.wireframe===!0){if(vt=Z.getWireframeAttribute(H),vt===void 0)return;Pt=2}const Nt=H.drawRange,_t=H.attributes.position;let $t=Nt.start*Pt,de=(Nt.start+Nt.count)*Pt;tt!==null&&($t=Math.max($t,tt.start*Pt),de=Math.min(de,(tt.start+tt.count)*Pt)),vt!==null?($t=Math.max($t,0),de=Math.min(de,vt.count)):_t!=null&&($t=Math.max($t,0),de=Math.min(de,_t.count));const pe=de-$t;if(pe<0||pe===1/0)return;ue.setup(F,V,gt,H,vt);let Ye,te=mt;if(vt!==null&&(Ye=K.get(vt),te=Xt,te.setIndex(Ye)),F.isMesh)V.wireframe===!0?(Tt.setLineWidth(V.wireframeLinewidth*Se()),te.setMode(O.LINES)):te.setMode(O.TRIANGLES);else if(F.isLine){let bt=V.linewidth;bt===void 0&&(bt=1),Tt.setLineWidth(bt*Se()),F.isLineSegments?te.setMode(O.LINES):F.isLineLoop?te.setMode(O.LINE_LOOP):te.setMode(O.LINE_STRIP)}else F.isPoints?te.setMode(O.POINTS):F.isSprite&&te.setMode(O.TRIANGLES);if(F.isBatchedMesh)if(F._multiDrawInstances!==null)te.renderMultiDrawInstances(F._multiDrawStarts,F._multiDrawCounts,F._multiDrawCount,F._multiDrawInstances);else if(Gt.get("WEBGL_multi_draw"))te.renderMultiDraw(F._multiDrawStarts,F._multiDrawCounts,F._multiDrawCount);else{const bt=F._multiDrawStarts,Fn=F._multiDrawCounts,ee=F._multiDrawCount,mn=vt?K.get(vt).bytesPerElement:1,Oi=wt.get(V).currentProgram.getUniforms();for(let je=0;je<ee;je++)Oi.setValue(O,"_gl_DrawID",je),te.render(bt[je]/mn,Fn[je])}else if(F.isInstancedMesh)te.renderInstances($t,pe,F.count);else if(H.isInstancedBufferGeometry){const bt=H._maxInstanceCount!==void 0?H._maxInstanceCount:1/0,Fn=Math.min(H.instanceCount,bt);te.renderInstances($t,pe,Fn)}else te.render($t,pe)};function ie(w,U,H){w.transparent===!0&&w.side===hn&&w.forceSinglePass===!1?(w.side=$e,w.needsUpdate=!0,lr(w,U,H),w.side=Zn,w.needsUpdate=!0,lr(w,U,H),w.side=hn):lr(w,U,H)}this.compile=function(w,U,H=null){H===null&&(H=w),p=Kt.get(H),p.init(U),y.push(p),H.traverseVisible(function(F){F.isLight&&F.layers.test(U.layers)&&(p.pushLight(F),F.castShadow&&p.pushShadow(F))}),w!==H&&w.traverseVisible(function(F){F.isLight&&F.layers.test(U.layers)&&(p.pushLight(F),F.castShadow&&p.pushShadow(F))}),p.setupLights();const V=new Set;return w.traverse(function(F){if(!(F.isMesh||F.isPoints||F.isLine||F.isSprite))return;const tt=F.material;if(tt)if(Array.isArray(tt))for(let ht=0;ht<tt.length;ht++){const gt=tt[ht];ie(gt,H,F),V.add(gt)}else ie(tt,H,F),V.add(tt)}),y.pop(),p=null,V},this.compileAsync=function(w,U,H=null){const V=this.compile(w,U,H);return new Promise(F=>{function tt(){if(V.forEach(function(ht){wt.get(ht).currentProgram.isReady()&&V.delete(ht)}),V.size===0){F(w);return}setTimeout(tt,10)}Gt.get("KHR_parallel_shader_compile")!==null?tt():setTimeout(tt,10)})};let pn=null;function Un(w){pn&&pn(w)}function Pl(){yi.stop()}function Ll(){yi.start()}const yi=new ou;yi.setAnimationLoop(Un),typeof self<"u"&&yi.setContext(self),this.setAnimationLoop=function(w){pn=w,W.setAnimationLoop(w),w===null?yi.stop():yi.start()},W.addEventListener("sessionstart",Pl),W.addEventListener("sessionend",Ll),this.render=function(w,U){if(U!==void 0&&U.isCamera!==!0){console.error("THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.");return}if(I===!0)return;if(w.matrixWorldAutoUpdate===!0&&w.updateMatrixWorld(),U.parent===null&&U.matrixWorldAutoUpdate===!0&&U.updateMatrixWorld(),W.enabled===!0&&W.isPresenting===!0&&(W.cameraAutoUpdate===!0&&W.updateCamera(U),U=W.getCamera()),w.isScene===!0&&w.onBeforeRender(_,w,U,C),p=Kt.get(w,y.length),p.init(U),y.push(p),At.multiplyMatrices(U.projectionMatrix,U.matrixWorldInverse),Y.setFromProjectionMatrix(At),yt=this.localClippingEnabled,et=J.init(this.clippingPlanes,yt),g=ft.get(w,x.length),g.init(),x.push(g),W.enabled===!0&&W.isPresenting===!0){const tt=_.xr.getDepthSensingMesh();tt!==null&&da(tt,U,-1/0,_.sortObjects)}da(w,U,0,_.sortObjects),g.finish(),_.sortObjects===!0&&g.sort(it,lt),Yt=W.enabled===!1||W.isPresenting===!1||W.hasDepthSensing()===!1,Yt&&Et.addToRenderList(g,w),this.info.render.frame++,et===!0&&J.beginShadows();const H=p.state.shadowsArray;pt.render(H,w,U),et===!0&&J.endShadows(),this.info.autoReset===!0&&this.info.reset();const V=g.opaque,F=g.transmissive;if(p.setupLights(),U.isArrayCamera){const tt=U.cameras;if(F.length>0)for(let ht=0,gt=tt.length;ht<gt;ht++){const vt=tt[ht];Dl(V,F,w,vt)}Yt&&Et.render(w);for(let ht=0,gt=tt.length;ht<gt;ht++){const vt=tt[ht];Il(g,w,vt,vt.viewport)}}else F.length>0&&Dl(V,F,w,U),Yt&&Et.render(w),Il(g,w,U);C!==null&&(T.updateMultisampleRenderTarget(C),T.updateRenderTargetMipmap(C)),w.isScene===!0&&w.onAfterRender(_,w,U),ue.resetDefaultState(),b=-1,M=null,y.pop(),y.length>0?(p=y[y.length-1],et===!0&&J.setGlobalState(_.clippingPlanes,p.state.camera)):p=null,x.pop(),x.length>0?g=x[x.length-1]:g=null};function da(w,U,H,V){if(w.visible===!1)return;if(w.layers.test(U.layers)){if(w.isGroup)H=w.renderOrder;else if(w.isLOD)w.autoUpdate===!0&&w.update(U);else if(w.isLight)p.pushLight(w),w.castShadow&&p.pushShadow(w);else if(w.isSprite){if(!w.frustumCulled||Y.intersectsSprite(w)){V&&Bt.setFromMatrixPosition(w.matrixWorld).applyMatrix4(At);const ht=q.update(w),gt=w.material;gt.visible&&g.push(w,ht,gt,H,Bt.z,null)}}else if((w.isMesh||w.isLine||w.isPoints)&&(!w.frustumCulled||Y.intersectsObject(w))){const ht=q.update(w),gt=w.material;if(V&&(w.boundingSphere!==void 0?(w.boundingSphere===null&&w.computeBoundingSphere(),Bt.copy(w.boundingSphere.center)):(ht.boundingSphere===null&&ht.computeBoundingSphere(),Bt.copy(ht.boundingSphere.center)),Bt.applyMatrix4(w.matrixWorld).applyMatrix4(At)),Array.isArray(gt)){const vt=ht.groups;for(let Pt=0,Nt=vt.length;Pt<Nt;Pt++){const _t=vt[Pt],$t=gt[_t.materialIndex];$t&&$t.visible&&g.push(w,ht,$t,H,Bt.z,_t)}}else gt.visible&&g.push(w,ht,gt,H,Bt.z,null)}}const tt=w.children;for(let ht=0,gt=tt.length;ht<gt;ht++)da(tt[ht],U,H,V)}function Il(w,U,H,V){const F=w.opaque,tt=w.transmissive,ht=w.transparent;p.setupLightsView(H),et===!0&&J.setGlobalState(_.clippingPlanes,H),V&&Tt.viewport(L.copy(V)),F.length>0&&or(F,U,H),tt.length>0&&or(tt,U,H),ht.length>0&&or(ht,U,H),Tt.buffers.depth.setTest(!0),Tt.buffers.depth.setMask(!0),Tt.buffers.color.setMask(!0),Tt.setPolygonOffset(!1)}function Dl(w,U,H,V){if((H.isScene===!0?H.overrideMaterial:null)!==null)return;p.state.transmissionRenderTarget[V.id]===void 0&&(p.state.transmissionRenderTarget[V.id]=new fn(1,1,{generateMipmaps:!0,type:Gt.has("EXT_color_buffer_half_float")||Gt.has("EXT_color_buffer_float")?Pn:Jn,minFilter:qn,samples:4,stencilBuffer:s,resolveDepthBuffer:!1,resolveStencilBuffer:!1,colorSpace:Ht.workingColorSpace}));const tt=p.state.transmissionRenderTarget[V.id],ht=V.viewport||L;tt.setSize(ht.z,ht.w);const gt=_.getRenderTarget();_.setRenderTarget(tt),_.getClearColor(B),j=_.getClearAlpha(),j<1&&_.setClearColor(16777215,.5),_.clear(),Yt&&Et.render(H);const vt=_.toneMapping;_.toneMapping=gi;const Pt=V.viewport;if(V.viewport!==void 0&&(V.viewport=void 0),p.setupLightsView(V),et===!0&&J.setGlobalState(_.clippingPlanes,V),or(w,H,V),T.updateMultisampleRenderTarget(tt),T.updateRenderTargetMipmap(tt),Gt.has("WEBGL_multisampled_render_to_texture")===!1){let Nt=!1;for(let _t=0,$t=U.length;_t<$t;_t++){const de=U[_t],pe=de.object,Ye=de.geometry,te=de.material,bt=de.group;if(te.side===hn&&pe.layers.test(V.layers)){const Fn=te.side;te.side=$e,te.needsUpdate=!0,Nl(pe,H,V,Ye,te,bt),te.side=Fn,te.needsUpdate=!0,Nt=!0}}Nt===!0&&(T.updateMultisampleRenderTarget(tt),T.updateRenderTargetMipmap(tt))}_.setRenderTarget(gt),_.setClearColor(B,j),Pt!==void 0&&(V.viewport=Pt),_.toneMapping=vt}function or(w,U,H){const V=U.isScene===!0?U.overrideMaterial:null;for(let F=0,tt=w.length;F<tt;F++){const ht=w[F],gt=ht.object,vt=ht.geometry,Pt=V===null?ht.material:V,Nt=ht.group;gt.layers.test(H.layers)&&Nl(gt,U,H,vt,Pt,Nt)}}function Nl(w,U,H,V,F,tt){w.onBeforeRender(_,U,H,V,F,tt),w.modelViewMatrix.multiplyMatrices(H.matrixWorldInverse,w.matrixWorld),w.normalMatrix.getNormalMatrix(w.modelViewMatrix),F.onBeforeRender(_,U,H,V,w,tt),F.transparent===!0&&F.side===hn&&F.forceSinglePass===!1?(F.side=$e,F.needsUpdate=!0,_.renderBufferDirect(H,U,V,F,w,tt),F.side=Zn,F.needsUpdate=!0,_.renderBufferDirect(H,U,V,F,w,tt),F.side=hn):_.renderBufferDirect(H,U,V,F,w,tt),w.onAfterRender(_,U,H,V,F,tt)}function lr(w,U,H){U.isScene!==!0&&(U=ve);const V=wt.get(w),F=p.state.lights,tt=p.state.shadowsArray,ht=F.state.version,gt=Mt.getParameters(w,F.state,tt,U,H),vt=Mt.getProgramCacheKey(gt);let Pt=V.programs;V.environment=w.isMeshStandardMaterial?U.environment:null,V.fog=U.fog,V.envMap=(w.isMeshStandardMaterial?k:S).get(w.envMap||V.environment),V.envMapRotation=V.environment!==null&&w.envMap===null?U.environmentRotation:w.envMapRotation,Pt===void 0&&(w.addEventListener("dispose",Dt),Pt=new Map,V.programs=Pt);let Nt=Pt.get(vt);if(Nt!==void 0){if(V.currentProgram===Nt&&V.lightsStateVersion===ht)return Fl(w,gt),Nt}else gt.uniforms=Mt.getUniforms(w),w.onBeforeCompile(gt,_),Nt=Mt.acquireProgram(gt,vt),Pt.set(vt,Nt),V.uniforms=gt.uniforms;const _t=V.uniforms;return(!w.isShaderMaterial&&!w.isRawShaderMaterial||w.clipping===!0)&&(_t.clippingPlanes=J.uniform),Fl(w,gt),V.needsLights=ju(w),V.lightsStateVersion=ht,V.needsLights&&(_t.ambientLightColor.value=F.state.ambient,_t.lightProbe.value=F.state.probe,_t.directionalLights.value=F.state.directional,_t.directionalLightShadows.value=F.state.directionalShadow,_t.spotLights.value=F.state.spot,_t.spotLightShadows.value=F.state.spotShadow,_t.rectAreaLights.value=F.state.rectArea,_t.ltc_1.value=F.state.rectAreaLTC1,_t.ltc_2.value=F.state.rectAreaLTC2,_t.pointLights.value=F.state.point,_t.pointLightShadows.value=F.state.pointShadow,_t.hemisphereLights.value=F.state.hemi,_t.directionalShadowMap.value=F.state.directionalShadowMap,_t.directionalShadowMatrix.value=F.state.directionalShadowMatrix,_t.spotShadowMap.value=F.state.spotShadowMap,_t.spotLightMatrix.value=F.state.spotLightMatrix,_t.spotLightMap.value=F.state.spotLightMap,_t.pointShadowMap.value=F.state.pointShadowMap,_t.pointShadowMatrix.value=F.state.pointShadowMatrix),V.currentProgram=Nt,V.uniformsList=null,Nt}function Ul(w){if(w.uniformsList===null){const U=w.currentProgram.getUniforms();w.uniformsList=Xr.seqWithValue(U.seq,w.uniforms)}return w.uniformsList}function Fl(w,U){const H=wt.get(w);H.outputColorSpace=U.outputColorSpace,H.batching=U.batching,H.batchingColor=U.batchingColor,H.instancing=U.instancing,H.instancingColor=U.instancingColor,H.instancingMorph=U.instancingMorph,H.skinning=U.skinning,H.morphTargets=U.morphTargets,H.morphNormals=U.morphNormals,H.morphColors=U.morphColors,H.morphTargetsCount=U.morphTargetsCount,H.numClippingPlanes=U.numClippingPlanes,H.numIntersection=U.numClipIntersection,H.vertexAlphas=U.vertexAlphas,H.vertexTangents=U.vertexTangents,H.toneMapping=U.toneMapping}function Ku(w,U,H,V,F){U.isScene!==!0&&(U=ve),T.resetTextureUnits();const tt=U.fog,ht=V.isMeshStandardMaterial?U.environment:null,gt=C===null?_.outputColorSpace:C.isXRRenderTarget===!0?C.texture.colorSpace:qe,vt=(V.isMeshStandardMaterial?k:S).get(V.envMap||ht),Pt=V.vertexColors===!0&&!!H.attributes.color&&H.attributes.color.itemSize===4,Nt=!!H.attributes.tangent&&(!!V.normalMap||V.anisotropy>0),_t=!!H.morphAttributes.position,$t=!!H.morphAttributes.normal,de=!!H.morphAttributes.color;let pe=gi;V.toneMapped&&(C===null||C.isXRRenderTarget===!0)&&(pe=_.toneMapping);const Ye=H.morphAttributes.position||H.morphAttributes.normal||H.morphAttributes.color,te=Ye!==void 0?Ye.length:0,bt=wt.get(V),Fn=p.state.lights;if(et===!0&&(yt===!0||w!==M)){const sn=w===M&&V.id===b;J.setState(V,w,sn)}let ee=!1;V.version===bt.__version?(bt.needsLights&&bt.lightsStateVersion!==Fn.state.version||bt.outputColorSpace!==gt||F.isBatchedMesh&&bt.batching===!1||!F.isBatchedMesh&&bt.batching===!0||F.isBatchedMesh&&bt.batchingColor===!0&&F.colorTexture===null||F.isBatchedMesh&&bt.batchingColor===!1&&F.colorTexture!==null||F.isInstancedMesh&&bt.instancing===!1||!F.isInstancedMesh&&bt.instancing===!0||F.isSkinnedMesh&&bt.skinning===!1||!F.isSkinnedMesh&&bt.skinning===!0||F.isInstancedMesh&&bt.instancingColor===!0&&F.instanceColor===null||F.isInstancedMesh&&bt.instancingColor===!1&&F.instanceColor!==null||F.isInstancedMesh&&bt.instancingMorph===!0&&F.morphTexture===null||F.isInstancedMesh&&bt.instancingMorph===!1&&F.morphTexture!==null||bt.envMap!==vt||V.fog===!0&&bt.fog!==tt||bt.numClippingPlanes!==void 0&&(bt.numClippingPlanes!==J.numPlanes||bt.numIntersection!==J.numIntersection)||bt.vertexAlphas!==Pt||bt.vertexTangents!==Nt||bt.morphTargets!==_t||bt.morphNormals!==$t||bt.morphColors!==de||bt.toneMapping!==pe||bt.morphTargetsCount!==te)&&(ee=!0):(ee=!0,bt.__version=V.version);let mn=bt.currentProgram;ee===!0&&(mn=lr(V,U,F));let Oi=!1,je=!1,Ts=!1;const me=mn.getUniforms(),An=bt.uniforms;if(Tt.useProgram(mn.program)&&(Oi=!0,je=!0,Ts=!0),V.id!==b&&(b=V.id,je=!0),Oi||M!==w){Tt.buffers.depth.getReversed()?(at.copy(w.projectionMatrix),Jd(at),Qd(at),me.setValue(O,"projectionMatrix",at)):me.setValue(O,"projectionMatrix",w.projectionMatrix),me.setValue(O,"viewMatrix",w.matrixWorldInverse);const ti=me.map.cameraPosition;ti!==void 0&&ti.setValue(O,Lt.setFromMatrixPosition(w.matrixWorld)),Wt.logarithmicDepthBuffer&&me.setValue(O,"logDepthBufFC",2/(Math.log(w.far+1)/Math.LN2)),(V.isMeshPhongMaterial||V.isMeshToonMaterial||V.isMeshLambertMaterial||V.isMeshBasicMaterial||V.isMeshStandardMaterial||V.isShaderMaterial)&&me.setValue(O,"isOrthographic",w.isOrthographicCamera===!0),M!==w&&(M=w,je=!0,Ts=!0)}if(F.isSkinnedMesh){me.setOptional(O,F,"bindMatrix"),me.setOptional(O,F,"bindMatrixInverse");const sn=F.skeleton;sn&&(sn.boneTexture===null&&sn.computeBoneTexture(),me.setValue(O,"boneTexture",sn.boneTexture,T))}F.isBatchedMesh&&(me.setOptional(O,F,"batchingTexture"),me.setValue(O,"batchingTexture",F._matricesTexture,T),me.setOptional(O,F,"batchingIdTexture"),me.setValue(O,"batchingIdTexture",F._indirectTexture,T),me.setOptional(O,F,"batchingColorTexture"),F._colorsTexture!==null&&me.setValue(O,"batchingColorTexture",F._colorsTexture,T));const Es=H.morphAttributes;if((Es.position!==void 0||Es.normal!==void 0||Es.color!==void 0)&&Ct.update(F,H,mn),(je||bt.receiveShadow!==F.receiveShadow)&&(bt.receiveShadow=F.receiveShadow,me.setValue(O,"receiveShadow",F.receiveShadow)),V.isMeshGouraudMaterial&&V.envMap!==null&&(An.envMap.value=vt,An.flipEnvMap.value=vt.isCubeTexture&&vt.isRenderTargetTexture===!1?-1:1),V.isMeshStandardMaterial&&V.envMap===null&&U.environment!==null&&(An.envMapIntensity.value=U.environmentIntensity),je&&(me.setValue(O,"toneMappingExposure",_.toneMappingExposure),bt.needsLights&&$u(An,Ts),tt&&V.fog===!0&&ot.refreshFogUniforms(An,tt),ot.refreshMaterialUniforms(An,V,G,Q,p.state.transmissionRenderTarget[w.id]),Xr.upload(O,Ul(bt),An,T)),V.isShaderMaterial&&V.uniformsNeedUpdate===!0&&(Xr.upload(O,Ul(bt),An,T),V.uniformsNeedUpdate=!1),V.isSpriteMaterial&&me.setValue(O,"center",F.center),me.setValue(O,"modelViewMatrix",F.modelViewMatrix),me.setValue(O,"normalMatrix",F.normalMatrix),me.setValue(O,"modelMatrix",F.matrixWorld),V.isShaderMaterial||V.isRawShaderMaterial){const sn=V.uniformsGroups;for(let ti=0,ei=sn.length;ti<ei;ti++){const Ol=sn[ti];N.update(Ol,mn),N.bind(Ol,mn)}}return mn}function $u(w,U){w.ambientLightColor.needsUpdate=U,w.lightProbe.needsUpdate=U,w.directionalLights.needsUpdate=U,w.directionalLightShadows.needsUpdate=U,w.pointLights.needsUpdate=U,w.pointLightShadows.needsUpdate=U,w.spotLights.needsUpdate=U,w.spotLightShadows.needsUpdate=U,w.rectAreaLights.needsUpdate=U,w.hemisphereLights.needsUpdate=U}function ju(w){return w.isMeshLambertMaterial||w.isMeshToonMaterial||w.isMeshPhongMaterial||w.isMeshStandardMaterial||w.isShadowMaterial||w.isShaderMaterial&&w.lights===!0}this.getActiveCubeFace=function(){return E},this.getActiveMipmapLevel=function(){return A},this.getRenderTarget=function(){return C},this.setRenderTargetTextures=function(w,U,H){wt.get(w.texture).__webglTexture=U,wt.get(w.depthTexture).__webglTexture=H;const V=wt.get(w);V.__hasExternalTextures=!0,V.__autoAllocateDepthBuffer=H===void 0,V.__autoAllocateDepthBuffer||Gt.has("WEBGL_multisampled_render_to_texture")===!0&&(console.warn("THREE.WebGLRenderer: Render-to-texture extension was disabled because an external texture was provided"),V.__useRenderToTexture=!1)},this.setRenderTargetFramebuffer=function(w,U){const H=wt.get(w);H.__webglFramebuffer=U,H.__useDefaultFramebuffer=U===void 0},this.setRenderTarget=function(w,U=0,H=0){C=w,E=U,A=H;let V=!0,F=null,tt=!1,ht=!1;if(w){const vt=wt.get(w);if(vt.__useDefaultFramebuffer!==void 0)Tt.bindFramebuffer(O.FRAMEBUFFER,null),V=!1;else if(vt.__webglFramebuffer===void 0)T.setupRenderTarget(w);else if(vt.__hasExternalTextures)T.rebindTextures(w,wt.get(w.texture).__webglTexture,wt.get(w.depthTexture).__webglTexture);else if(w.depthBuffer){const _t=w.depthTexture;if(vt.__boundDepthTexture!==_t){if(_t!==null&&wt.has(_t)&&(w.width!==_t.image.width||w.height!==_t.image.height))throw new Error("WebGLRenderTarget: Attached DepthTexture is initialized to the incorrect size.");T.setupDepthRenderbuffer(w)}}const Pt=w.texture;(Pt.isData3DTexture||Pt.isDataArrayTexture||Pt.isCompressedArrayTexture)&&(ht=!0);const Nt=wt.get(w).__webglFramebuffer;w.isWebGLCubeRenderTarget?(Array.isArray(Nt[U])?F=Nt[U][H]:F=Nt[U],tt=!0):w.samples>0&&T.useMultisampledRTT(w)===!1?F=wt.get(w).__webglMultisampledFramebuffer:Array.isArray(Nt)?F=Nt[H]:F=Nt,L.copy(w.viewport),z.copy(w.scissor),R=w.scissorTest}else L.copy(St).multiplyScalar(G).floor(),z.copy(kt).multiplyScalar(G).floor(),R=ce;if(Tt.bindFramebuffer(O.FRAMEBUFFER,F)&&V&&Tt.drawBuffers(w,F),Tt.viewport(L),Tt.scissor(z),Tt.setScissorTest(R),tt){const vt=wt.get(w.texture);O.framebufferTexture2D(O.FRAMEBUFFER,O.COLOR_ATTACHMENT0,O.TEXTURE_CUBE_MAP_POSITIVE_X+U,vt.__webglTexture,H)}else if(ht){const vt=wt.get(w.texture),Pt=U||0;O.framebufferTextureLayer(O.FRAMEBUFFER,O.COLOR_ATTACHMENT0,vt.__webglTexture,H||0,Pt)}b=-1},this.readRenderTargetPixels=function(w,U,H,V,F,tt,ht){if(!(w&&w.isWebGLRenderTarget)){console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.");return}let gt=wt.get(w).__webglFramebuffer;if(w.isWebGLCubeRenderTarget&&ht!==void 0&&(gt=gt[ht]),gt){Tt.bindFramebuffer(O.FRAMEBUFFER,gt);try{const vt=w.texture,Pt=vt.format,Nt=vt.type;if(!Wt.textureFormatReadable(Pt)){console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in RGBA or implementation defined format.");return}if(!Wt.textureTypeReadable(Nt)){console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in UnsignedByteType or implementation defined type.");return}U>=0&&U<=w.width-V&&H>=0&&H<=w.height-F&&O.readPixels(U,H,V,F,Ft.convert(Pt),Ft.convert(Nt),tt)}finally{const vt=C!==null?wt.get(C).__webglFramebuffer:null;Tt.bindFramebuffer(O.FRAMEBUFFER,vt)}}},this.readRenderTargetPixelsAsync=async function(w,U,H,V,F,tt,ht){if(!(w&&w.isWebGLRenderTarget))throw new Error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.");let gt=wt.get(w).__webglFramebuffer;if(w.isWebGLCubeRenderTarget&&ht!==void 0&&(gt=gt[ht]),gt){const vt=w.texture,Pt=vt.format,Nt=vt.type;if(!Wt.textureFormatReadable(Pt))throw new Error("THREE.WebGLRenderer.readRenderTargetPixelsAsync: renderTarget is not in RGBA or implementation defined format.");if(!Wt.textureTypeReadable(Nt))throw new Error("THREE.WebGLRenderer.readRenderTargetPixelsAsync: renderTarget is not in UnsignedByteType or implementation defined type.");if(U>=0&&U<=w.width-V&&H>=0&&H<=w.height-F){Tt.bindFramebuffer(O.FRAMEBUFFER,gt);const _t=O.createBuffer();O.bindBuffer(O.PIXEL_PACK_BUFFER,_t),O.bufferData(O.PIXEL_PACK_BUFFER,tt.byteLength,O.STREAM_READ),O.readPixels(U,H,V,F,Ft.convert(Pt),Ft.convert(Nt),0);const $t=C!==null?wt.get(C).__webglFramebuffer:null;Tt.bindFramebuffer(O.FRAMEBUFFER,$t);const de=O.fenceSync(O.SYNC_GPU_COMMANDS_COMPLETE,0);return O.flush(),await Zd(O,de,4),O.bindBuffer(O.PIXEL_PACK_BUFFER,_t),O.getBufferSubData(O.PIXEL_PACK_BUFFER,0,tt),O.deleteBuffer(_t),O.deleteSync(de),tt}else throw new Error("THREE.WebGLRenderer.readRenderTargetPixelsAsync: requested read bounds are out of range.")}},this.copyFramebufferToTexture=function(w,U=null,H=0){w.isTexture!==!0&&(zs("WebGLRenderer: copyFramebufferToTexture function signature has changed."),U=arguments[0]||null,w=arguments[1]);const V=Math.pow(2,-H),F=Math.floor(w.image.width*V),tt=Math.floor(w.image.height*V),ht=U!==null?U.x:0,gt=U!==null?U.y:0;T.setTexture2D(w,0),O.copyTexSubImage2D(O.TEXTURE_2D,H,0,0,ht,gt,F,tt),Tt.unbindTexture()},this.copyTextureToTexture=function(w,U,H=null,V=null,F=0){w.isTexture!==!0&&(zs("WebGLRenderer: copyTextureToTexture function signature has changed."),V=arguments[0]||null,w=arguments[1],U=arguments[2],F=arguments[3]||0,H=null);let tt,ht,gt,vt,Pt,Nt,_t,$t,de;const pe=w.isCompressedTexture?w.mipmaps[F]:w.image;H!==null?(tt=H.max.x-H.min.x,ht=H.max.y-H.min.y,gt=H.isBox3?H.max.z-H.min.z:1,vt=H.min.x,Pt=H.min.y,Nt=H.isBox3?H.min.z:0):(tt=pe.width,ht=pe.height,gt=pe.depth||1,vt=0,Pt=0,Nt=0),V!==null?(_t=V.x,$t=V.y,de=V.z):(_t=0,$t=0,de=0);const Ye=Ft.convert(U.format),te=Ft.convert(U.type);let bt;U.isData3DTexture?(T.setTexture3D(U,0),bt=O.TEXTURE_3D):U.isDataArrayTexture||U.isCompressedArrayTexture?(T.setTexture2DArray(U,0),bt=O.TEXTURE_2D_ARRAY):(T.setTexture2D(U,0),bt=O.TEXTURE_2D),O.pixelStorei(O.UNPACK_FLIP_Y_WEBGL,U.flipY),O.pixelStorei(O.UNPACK_PREMULTIPLY_ALPHA_WEBGL,U.premultiplyAlpha),O.pixelStorei(O.UNPACK_ALIGNMENT,U.unpackAlignment);const Fn=O.getParameter(O.UNPACK_ROW_LENGTH),ee=O.getParameter(O.UNPACK_IMAGE_HEIGHT),mn=O.getParameter(O.UNPACK_SKIP_PIXELS),Oi=O.getParameter(O.UNPACK_SKIP_ROWS),je=O.getParameter(O.UNPACK_SKIP_IMAGES);O.pixelStorei(O.UNPACK_ROW_LENGTH,pe.width),O.pixelStorei(O.UNPACK_IMAGE_HEIGHT,pe.height),O.pixelStorei(O.UNPACK_SKIP_PIXELS,vt),O.pixelStorei(O.UNPACK_SKIP_ROWS,Pt),O.pixelStorei(O.UNPACK_SKIP_IMAGES,Nt);const Ts=w.isDataArrayTexture||w.isData3DTexture,me=U.isDataArrayTexture||U.isData3DTexture;if(w.isRenderTargetTexture||w.isDepthTexture){const An=wt.get(w),Es=wt.get(U),sn=wt.get(An.__renderTarget),ti=wt.get(Es.__renderTarget);Tt.bindFramebuffer(O.READ_FRAMEBUFFER,sn.__webglFramebuffer),Tt.bindFramebuffer(O.DRAW_FRAMEBUFFER,ti.__webglFramebuffer);for(let ei=0;ei<gt;ei++)Ts&&O.framebufferTextureLayer(O.READ_FRAMEBUFFER,O.COLOR_ATTACHMENT0,wt.get(w).__webglTexture,F,Nt+ei),w.isDepthTexture?(me&&O.framebufferTextureLayer(O.DRAW_FRAMEBUFFER,O.COLOR_ATTACHMENT0,wt.get(U).__webglTexture,F,de+ei),O.blitFramebuffer(vt,Pt,tt,ht,_t,$t,tt,ht,O.DEPTH_BUFFER_BIT,O.NEAREST)):me?O.copyTexSubImage3D(bt,F,_t,$t,de+ei,vt,Pt,tt,ht):O.copyTexSubImage2D(bt,F,_t,$t,de+ei,vt,Pt,tt,ht);Tt.bindFramebuffer(O.READ_FRAMEBUFFER,null),Tt.bindFramebuffer(O.DRAW_FRAMEBUFFER,null)}else me?w.isDataTexture||w.isData3DTexture?O.texSubImage3D(bt,F,_t,$t,de,tt,ht,gt,Ye,te,pe.data):U.isCompressedArrayTexture?O.compressedTexSubImage3D(bt,F,_t,$t,de,tt,ht,gt,Ye,pe.data):O.texSubImage3D(bt,F,_t,$t,de,tt,ht,gt,Ye,te,pe):w.isDataTexture?O.texSubImage2D(O.TEXTURE_2D,F,_t,$t,tt,ht,Ye,te,pe.data):w.isCompressedTexture?O.compressedTexSubImage2D(O.TEXTURE_2D,F,_t,$t,pe.width,pe.height,Ye,pe.data):O.texSubImage2D(O.TEXTURE_2D,F,_t,$t,tt,ht,Ye,te,pe);O.pixelStorei(O.UNPACK_ROW_LENGTH,Fn),O.pixelStorei(O.UNPACK_IMAGE_HEIGHT,ee),O.pixelStorei(O.UNPACK_SKIP_PIXELS,mn),O.pixelStorei(O.UNPACK_SKIP_ROWS,Oi),O.pixelStorei(O.UNPACK_SKIP_IMAGES,je),F===0&&U.generateMipmaps&&O.generateMipmap(bt),Tt.unbindTexture()},this.copyTextureToTexture3D=function(w,U,H=null,V=null,F=0){return w.isTexture!==!0&&(zs("WebGLRenderer: copyTextureToTexture3D function signature has changed."),H=arguments[0]||null,V=arguments[1]||null,w=arguments[2],U=arguments[3],F=arguments[4]||0),zs('WebGLRenderer: copyTextureToTexture3D function has been deprecated. Use "copyTextureToTexture" instead.'),this.copyTextureToTexture(w,U,H,V,F)},this.initRenderTarget=function(w){wt.get(w).__webglFramebuffer===void 0&&T.setupRenderTarget(w)},this.initTexture=function(w){w.isCubeTexture?T.setTextureCube(w,0):w.isData3DTexture?T.setTexture3D(w,0):w.isDataArrayTexture||w.isCompressedArrayTexture?T.setTexture2DArray(w,0):T.setTexture2D(w,0),Tt.unbindTexture()},this.resetState=function(){E=0,A=0,C=null,Tt.reset(),ue.reset()},typeof __THREE_DEVTOOLS__<"u"&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe",{detail:this}))}get coordinateSystem(){return Kn}get outputColorSpace(){return this._outputColorSpace}set outputColorSpace(t){this._outputColorSpace=t;const e=this.getContext();e.drawingBufferColorspace=Ht._getDrawingBufferColorSpace(t),e.unpackColorSpace=Ht._getUnpackColorSpace()}}class pl{constructor(t,e=1,n=1e3){this.isFog=!0,this.name="",this.color=new dt(t),this.near=e,this.far=n}clone(){return new pl(this.color,this.near,this.far)}toJSON(){return{type:"Fog",name:this.name,color:this.color.getHex(),near:this.near,far:this.far}}}class cv extends he{constructor(){super(),this.isScene=!0,this.type="Scene",this.background=null,this.environment=null,this.fog=null,this.backgroundBlurriness=0,this.backgroundIntensity=1,this.backgroundRotation=new En,this.environmentIntensity=1,this.environmentRotation=new En,this.overrideMaterial=null,typeof __THREE_DEVTOOLS__<"u"&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe",{detail:this}))}copy(t,e){return super.copy(t,e),t.background!==null&&(this.background=t.background.clone()),t.environment!==null&&(this.environment=t.environment.clone()),t.fog!==null&&(this.fog=t.fog.clone()),this.backgroundBlurriness=t.backgroundBlurriness,this.backgroundIntensity=t.backgroundIntensity,this.backgroundRotation.copy(t.backgroundRotation),this.environmentIntensity=t.environmentIntensity,this.environmentRotation.copy(t.environmentRotation),t.overrideMaterial!==null&&(this.overrideMaterial=t.overrideMaterial.clone()),this.matrixAutoUpdate=t.matrixAutoUpdate,this}toJSON(t){const e=super.toJSON(t);return this.fog!==null&&(e.object.fog=this.fog.toJSON()),this.backgroundBlurriness>0&&(e.object.backgroundBlurriness=this.backgroundBlurriness),this.backgroundIntensity!==1&&(e.object.backgroundIntensity=this.backgroundIntensity),e.object.backgroundRotation=this.backgroundRotation.toArray(),this.environmentIntensity!==1&&(e.object.environmentIntensity=this.environmentIntensity),e.object.environmentRotation=this.environmentRotation.toArray(),e}}class hv{constructor(t,e){this.isInterleavedBuffer=!0,this.array=t,this.stride=e,this.count=t!==void 0?t.length/e:0,this.usage=Ho,this.updateRanges=[],this.version=0,this.uuid=wn()}onUploadCallback(){}set needsUpdate(t){t===!0&&this.version++}setUsage(t){return this.usage=t,this}addUpdateRange(t,e){this.updateRanges.push({start:t,count:e})}clearUpdateRanges(){this.updateRanges.length=0}copy(t){return this.array=new t.array.constructor(t.array),this.count=t.count,this.stride=t.stride,this.usage=t.usage,this}copyAt(t,e,n){t*=this.stride,n*=e.stride;for(let i=0,s=this.stride;i<s;i++)this.array[t+i]=e.array[n+i];return this}set(t,e=0){return this.array.set(t,e),this}clone(t){t.arrayBuffers===void 0&&(t.arrayBuffers={}),this.array.buffer._uuid===void 0&&(this.array.buffer._uuid=wn()),t.arrayBuffers[this.array.buffer._uuid]===void 0&&(t.arrayBuffers[this.array.buffer._uuid]=this.array.slice(0).buffer);const e=new this.array.constructor(t.arrayBuffers[this.array.buffer._uuid]),n=new this.constructor(e,this.stride);return n.setUsage(this.usage),n}onUpload(t){return this.onUploadCallback=t,this}toJSON(t){return t.arrayBuffers===void 0&&(t.arrayBuffers={}),this.array.buffer._uuid===void 0&&(this.array.buffer._uuid=wn()),t.arrayBuffers[this.array.buffer._uuid]===void 0&&(t.arrayBuffers[this.array.buffer._uuid]=Array.from(new Uint32Array(this.array.buffer))),{uuid:this.uuid,buffer:this.array.buffer._uuid,type:this.array.constructor.name,stride:this.stride}}}const He=new P;class ml{constructor(t,e,n,i=!1){this.isInterleavedBufferAttribute=!0,this.name="",this.data=t,this.itemSize=e,this.offset=n,this.normalized=i}get count(){return this.data.count}get array(){return this.data.array}set needsUpdate(t){this.data.needsUpdate=t}applyMatrix4(t){for(let e=0,n=this.data.count;e<n;e++)He.fromBufferAttribute(this,e),He.applyMatrix4(t),this.setXYZ(e,He.x,He.y,He.z);return this}applyNormalMatrix(t){for(let e=0,n=this.count;e<n;e++)He.fromBufferAttribute(this,e),He.applyNormalMatrix(t),this.setXYZ(e,He.x,He.y,He.z);return this}transformDirection(t){for(let e=0,n=this.count;e<n;e++)He.fromBufferAttribute(this,e),He.transformDirection(t),this.setXYZ(e,He.x,He.y,He.z);return this}getComponent(t,e){let n=this.array[t*this.data.stride+this.offset+e];return this.normalized&&(n=Mn(n,this.array)),n}setComponent(t,e,n){return this.normalized&&(n=ae(n,this.array)),this.data.array[t*this.data.stride+this.offset+e]=n,this}setX(t,e){return this.normalized&&(e=ae(e,this.array)),this.data.array[t*this.data.stride+this.offset]=e,this}setY(t,e){return this.normalized&&(e=ae(e,this.array)),this.data.array[t*this.data.stride+this.offset+1]=e,this}setZ(t,e){return this.normalized&&(e=ae(e,this.array)),this.data.array[t*this.data.stride+this.offset+2]=e,this}setW(t,e){return this.normalized&&(e=ae(e,this.array)),this.data.array[t*this.data.stride+this.offset+3]=e,this}getX(t){let e=this.data.array[t*this.data.stride+this.offset];return this.normalized&&(e=Mn(e,this.array)),e}getY(t){let e=this.data.array[t*this.data.stride+this.offset+1];return this.normalized&&(e=Mn(e,this.array)),e}getZ(t){let e=this.data.array[t*this.data.stride+this.offset+2];return this.normalized&&(e=Mn(e,this.array)),e}getW(t){let e=this.data.array[t*this.data.stride+this.offset+3];return this.normalized&&(e=Mn(e,this.array)),e}setXY(t,e,n){return t=t*this.data.stride+this.offset,this.normalized&&(e=ae(e,this.array),n=ae(n,this.array)),this.data.array[t+0]=e,this.data.array[t+1]=n,this}setXYZ(t,e,n,i){return t=t*this.data.stride+this.offset,this.normalized&&(e=ae(e,this.array),n=ae(n,this.array),i=ae(i,this.array)),this.data.array[t+0]=e,this.data.array[t+1]=n,this.data.array[t+2]=i,this}setXYZW(t,e,n,i,s){return t=t*this.data.stride+this.offset,this.normalized&&(e=ae(e,this.array),n=ae(n,this.array),i=ae(i,this.array),s=ae(s,this.array)),this.data.array[t+0]=e,this.data.array[t+1]=n,this.data.array[t+2]=i,this.data.array[t+3]=s,this}clone(t){if(t===void 0){console.log("THREE.InterleavedBufferAttribute.clone(): Cloning an interleaved buffer attribute will de-interleave buffer data.");const e=[];for(let n=0;n<this.count;n++){const i=n*this.data.stride+this.offset;for(let s=0;s<this.itemSize;s++)e.push(this.data.array[i+s])}return new ge(new this.array.constructor(e),this.itemSize,this.normalized)}else return t.interleavedBuffers===void 0&&(t.interleavedBuffers={}),t.interleavedBuffers[this.data.uuid]===void 0&&(t.interleavedBuffers[this.data.uuid]=this.data.clone(t)),new ml(t.interleavedBuffers[this.data.uuid],this.itemSize,this.offset,this.normalized)}toJSON(t){if(t===void 0){console.log("THREE.InterleavedBufferAttribute.toJSON(): Serializing an interleaved buffer attribute will de-interleave buffer data.");const e=[];for(let n=0;n<this.count;n++){const i=n*this.data.stride+this.offset;for(let s=0;s<this.itemSize;s++)e.push(this.data.array[i+s])}return{itemSize:this.itemSize,type:this.array.constructor.name,array:e,normalized:this.normalized}}else return t.interleavedBuffers===void 0&&(t.interleavedBuffers={}),t.interleavedBuffers[this.data.uuid]===void 0&&(t.interleavedBuffers[this.data.uuid]=this.data.toJSON(t)),{isInterleavedBufferAttribute:!0,itemSize:this.itemSize,data:this.data.uuid,offset:this.offset,normalized:this.normalized}}}const Bc=new P,zc=new Qt,Hc=new Qt,uv=new P,Vc=new It,Cr=new P,Ha=new Ln,Gc=new It,Va=new ra;class dv extends Rt{constructor(t,e){super(t,e),this.isSkinnedMesh=!0,this.type="SkinnedMesh",this.bindMode=Hl,this.bindMatrix=new It,this.bindMatrixInverse=new It,this.boundingBox=null,this.boundingSphere=null}computeBoundingBox(){const t=this.geometry;this.boundingBox===null&&(this.boundingBox=new Qn),this.boundingBox.makeEmpty();const e=t.getAttribute("position");for(let n=0;n<e.count;n++)this.getVertexPosition(n,Cr),this.boundingBox.expandByPoint(Cr)}computeBoundingSphere(){const t=this.geometry;this.boundingSphere===null&&(this.boundingSphere=new Ln),this.boundingSphere.makeEmpty();const e=t.getAttribute("position");for(let n=0;n<e.count;n++)this.getVertexPosition(n,Cr),this.boundingSphere.expandByPoint(Cr)}copy(t,e){return super.copy(t,e),this.bindMode=t.bindMode,this.bindMatrix.copy(t.bindMatrix),this.bindMatrixInverse.copy(t.bindMatrixInverse),this.skeleton=t.skeleton,t.boundingBox!==null&&(this.boundingBox=t.boundingBox.clone()),t.boundingSphere!==null&&(this.boundingSphere=t.boundingSphere.clone()),this}raycast(t,e){const n=this.material,i=this.matrixWorld;n!==void 0&&(this.boundingSphere===null&&this.computeBoundingSphere(),Ha.copy(this.boundingSphere),Ha.applyMatrix4(i),t.ray.intersectsSphere(Ha)!==!1&&(Gc.copy(i).invert(),Va.copy(t.ray).applyMatrix4(Gc),!(this.boundingBox!==null&&Va.intersectsBox(this.boundingBox)===!1)&&this._computeIntersections(t,e,Va)))}getVertexPosition(t,e){return super.getVertexPosition(t,e),this.applyBoneTransform(t,e),e}bind(t,e){this.skeleton=t,e===void 0&&(this.updateMatrixWorld(!0),this.skeleton.calculateInverses(),e=this.matrixWorld),this.bindMatrix.copy(e),this.bindMatrixInverse.copy(e).invert()}pose(){this.skeleton.pose()}normalizeSkinWeights(){const t=new Qt,e=this.geometry.attributes.skinWeight;for(let n=0,i=e.count;n<i;n++){t.fromBufferAttribute(e,n);const s=1/t.manhattanLength();s!==1/0?t.multiplyScalar(s):t.set(1,0,0,0),e.setXYZW(n,t.x,t.y,t.z,t.w)}}updateMatrixWorld(t){super.updateMatrixWorld(t),this.bindMode===Hl?this.bindMatrixInverse.copy(this.matrixWorld).invert():this.bindMode===Md?this.bindMatrixInverse.copy(this.bindMatrix).invert():console.warn("THREE.SkinnedMesh: Unrecognized bindMode: "+this.bindMode)}applyBoneTransform(t,e){const n=this.skeleton,i=this.geometry;zc.fromBufferAttribute(i.attributes.skinIndex,t),Hc.fromBufferAttribute(i.attributes.skinWeight,t),Bc.copy(e).applyMatrix4(this.bindMatrix),e.set(0,0,0);for(let s=0;s<4;s++){const a=Hc.getComponent(s);if(a!==0){const o=zc.getComponent(s);Vc.multiplyMatrices(n.bones[o].matrixWorld,n.boneInverses[o]),e.addScaledVector(uv.copy(Bc).applyMatrix4(Vc),a)}}return e.applyMatrix4(this.bindMatrixInverse)}}class fu extends he{constructor(){super(),this.isBone=!0,this.type="Bone"}}class pu extends Ce{constructor(t=null,e=1,n=1,i,s,a,o,l,c=Xe,h=Xe,u,d){super(null,a,o,l,c,h,i,s,u,d),this.isDataTexture=!0,this.image={data:t,width:e,height:n},this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1}}const Wc=new It,fv=new It;class gl{constructor(t=[],e=[]){this.uuid=wn(),this.bones=t.slice(0),this.boneInverses=e,this.boneMatrices=null,this.boneTexture=null,this.init()}init(){const t=this.bones,e=this.boneInverses;if(this.boneMatrices=new Float32Array(t.length*16),e.length===0)this.calculateInverses();else if(t.length!==e.length){console.warn("THREE.Skeleton: Number of inverse bone matrices does not match amount of bones."),this.boneInverses=[];for(let n=0,i=this.bones.length;n<i;n++)this.boneInverses.push(new It)}}calculateInverses(){this.boneInverses.length=0;for(let t=0,e=this.bones.length;t<e;t++){const n=new It;this.bones[t]&&n.copy(this.bones[t].matrixWorld).invert(),this.boneInverses.push(n)}}pose(){for(let t=0,e=this.bones.length;t<e;t++){const n=this.bones[t];n&&n.matrixWorld.copy(this.boneInverses[t]).invert()}for(let t=0,e=this.bones.length;t<e;t++){const n=this.bones[t];n&&(n.parent&&n.parent.isBone?(n.matrix.copy(n.parent.matrixWorld).invert(),n.matrix.multiply(n.matrixWorld)):n.matrix.copy(n.matrixWorld),n.matrix.decompose(n.position,n.quaternion,n.scale))}}update(){const t=this.bones,e=this.boneInverses,n=this.boneMatrices,i=this.boneTexture;for(let s=0,a=t.length;s<a;s++){const o=t[s]?t[s].matrixWorld:fv;Wc.multiplyMatrices(o,e[s]),Wc.toArray(n,s*16)}i!==null&&(i.needsUpdate=!0)}clone(){return new gl(this.bones,this.boneInverses)}computeBoneTexture(){let t=Math.sqrt(this.bones.length*4);t=Math.ceil(t/4)*4,t=Math.max(t,4);const e=new Float32Array(t*t*4);e.set(this.boneMatrices);const n=new pu(e,t,t,un,Sn);return n.needsUpdate=!0,this.boneMatrices=e,this.boneTexture=n,this}getBoneByName(t){for(let e=0,n=this.bones.length;e<n;e++){const i=this.bones[e];if(i.name===t)return i}}dispose(){this.boneTexture!==null&&(this.boneTexture.dispose(),this.boneTexture=null)}fromJSON(t,e){this.uuid=t.uuid;for(let n=0,i=t.bones.length;n<i;n++){const s=t.bones[n];let a=e[s];a===void 0&&(console.warn("THREE.Skeleton: No bone found with UUID:",s),a=new fu),this.bones.push(a),this.boneInverses.push(new It().fromArray(t.boneInverses[n]))}return this.init(),this}toJSON(){const t={metadata:{version:4.6,type:"Skeleton",generator:"Skeleton.toJSON"},bones:[],boneInverses:[]};t.uuid=this.uuid;const e=this.bones,n=this.boneInverses;for(let i=0,s=e.length;i<s;i++){const a=e[i];t.bones.push(a.uuid);const o=n[i];t.boneInverses.push(o.toArray())}return t}}class Qs extends ge{constructor(t,e,n,i=1){super(t,e,n),this.isInstancedBufferAttribute=!0,this.meshPerAttribute=i}copy(t){return super.copy(t),this.meshPerAttribute=t.meshPerAttribute,this}toJSON(){const t=super.toJSON();return t.meshPerAttribute=this.meshPerAttribute,t.isInstancedBufferAttribute=!0,t}}const Ji=new It,Xc=new It,Pr=[],qc=new Qn,pv=new It,Ls=new Rt,Is=new Ln;class Ni extends Rt{constructor(t,e,n){super(t,e),this.isInstancedMesh=!0,this.instanceMatrix=new Qs(new Float32Array(n*16),16),this.instanceColor=null,this.morphTexture=null,this.count=n,this.boundingBox=null,this.boundingSphere=null;for(let i=0;i<n;i++)this.setMatrixAt(i,pv)}computeBoundingBox(){const t=this.geometry,e=this.count;this.boundingBox===null&&(this.boundingBox=new Qn),t.boundingBox===null&&t.computeBoundingBox(),this.boundingBox.makeEmpty();for(let n=0;n<e;n++)this.getMatrixAt(n,Ji),qc.copy(t.boundingBox).applyMatrix4(Ji),this.boundingBox.union(qc)}computeBoundingSphere(){const t=this.geometry,e=this.count;this.boundingSphere===null&&(this.boundingSphere=new Ln),t.boundingSphere===null&&t.computeBoundingSphere(),this.boundingSphere.makeEmpty();for(let n=0;n<e;n++)this.getMatrixAt(n,Ji),Is.copy(t.boundingSphere).applyMatrix4(Ji),this.boundingSphere.union(Is)}copy(t,e){return super.copy(t,e),this.instanceMatrix.copy(t.instanceMatrix),t.morphTexture!==null&&(this.morphTexture=t.morphTexture.clone()),t.instanceColor!==null&&(this.instanceColor=t.instanceColor.clone()),this.count=t.count,t.boundingBox!==null&&(this.boundingBox=t.boundingBox.clone()),t.boundingSphere!==null&&(this.boundingSphere=t.boundingSphere.clone()),this}getColorAt(t,e){e.fromArray(this.instanceColor.array,t*3)}getMatrixAt(t,e){e.fromArray(this.instanceMatrix.array,t*16)}getMorphAt(t,e){const n=e.morphTargetInfluences,i=this.morphTexture.source.data.data,s=n.length+1,a=t*s+1;for(let o=0;o<n.length;o++)n[o]=i[a+o]}raycast(t,e){const n=this.matrixWorld,i=this.count;if(Ls.geometry=this.geometry,Ls.material=this.material,Ls.material!==void 0&&(this.boundingSphere===null&&this.computeBoundingSphere(),Is.copy(this.boundingSphere),Is.applyMatrix4(n),t.ray.intersectsSphere(Is)!==!1))for(let s=0;s<i;s++){this.getMatrixAt(s,Ji),Xc.multiplyMatrices(n,Ji),Ls.matrixWorld=Xc,Ls.raycast(t,Pr);for(let a=0,o=Pr.length;a<o;a++){const l=Pr[a];l.instanceId=s,l.object=this,e.push(l)}Pr.length=0}}setColorAt(t,e){this.instanceColor===null&&(this.instanceColor=new Qs(new Float32Array(this.instanceMatrix.count*3).fill(1),3)),e.toArray(this.instanceColor.array,t*3)}setMatrixAt(t,e){e.toArray(this.instanceMatrix.array,t*16)}setMorphAt(t,e){const n=e.morphTargetInfluences,i=n.length+1;this.morphTexture===null&&(this.morphTexture=new pu(new Float32Array(i*this.count),i,this.count,al,Sn));const s=this.morphTexture.source.data.data;let a=0;for(let c=0;c<n.length;c++)a+=n[c];const o=this.geometry.morphTargetsRelative?1:1-a,l=i*t;s[l]=o,s.set(n,l+1)}updateMorphTargets(){}dispose(){return this.dispatchEvent({type:"dispose"}),this.morphTexture!==null&&(this.morphTexture.dispose(),this.morphTexture=null),this}}class mu extends Tn{static get type(){return"LineBasicMaterial"}constructor(t){super(),this.isLineBasicMaterial=!0,this.color=new dt(16777215),this.map=null,this.linewidth=1,this.linecap="round",this.linejoin="round",this.fog=!0,this.setValues(t)}copy(t){return super.copy(t),this.color.copy(t.color),this.map=t.map,this.linewidth=t.linewidth,this.linecap=t.linecap,this.linejoin=t.linejoin,this.fog=t.fog,this}}const Zr=new P,Jr=new P,Yc=new It,Ds=new ra,Lr=new Ln,Ga=new P,Kc=new P;class vl extends he{constructor(t=new ye,e=new mu){super(),this.isLine=!0,this.type="Line",this.geometry=t,this.material=e,this.updateMorphTargets()}copy(t,e){return super.copy(t,e),this.material=Array.isArray(t.material)?t.material.slice():t.material,this.geometry=t.geometry,this}computeLineDistances(){const t=this.geometry;if(t.index===null){const e=t.attributes.position,n=[0];for(let i=1,s=e.count;i<s;i++)Zr.fromBufferAttribute(e,i-1),Jr.fromBufferAttribute(e,i),n[i]=n[i-1],n[i]+=Zr.distanceTo(Jr);t.setAttribute("lineDistance",new Vt(n,1))}else console.warn("THREE.Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.");return this}raycast(t,e){const n=this.geometry,i=this.matrixWorld,s=t.params.Line.threshold,a=n.drawRange;if(n.boundingSphere===null&&n.computeBoundingSphere(),Lr.copy(n.boundingSphere),Lr.applyMatrix4(i),Lr.radius+=s,t.ray.intersectsSphere(Lr)===!1)return;Yc.copy(i).invert(),Ds.copy(t.ray).applyMatrix4(Yc);const o=s/((this.scale.x+this.scale.y+this.scale.z)/3),l=o*o,c=this.isLineSegments?2:1,h=n.index,d=n.attributes.position;if(h!==null){const f=Math.max(0,a.start),m=Math.min(h.count,a.start+a.count);for(let v=f,g=m-1;v<g;v+=c){const p=h.getX(v),x=h.getX(v+1),y=Ir(this,t,Ds,l,p,x);y&&e.push(y)}if(this.isLineLoop){const v=h.getX(m-1),g=h.getX(f),p=Ir(this,t,Ds,l,v,g);p&&e.push(p)}}else{const f=Math.max(0,a.start),m=Math.min(d.count,a.start+a.count);for(let v=f,g=m-1;v<g;v+=c){const p=Ir(this,t,Ds,l,v,v+1);p&&e.push(p)}if(this.isLineLoop){const v=Ir(this,t,Ds,l,m-1,f);v&&e.push(v)}}}updateMorphTargets(){const e=this.geometry.morphAttributes,n=Object.keys(e);if(n.length>0){const i=e[n[0]];if(i!==void 0){this.morphTargetInfluences=[],this.morphTargetDictionary={};for(let s=0,a=i.length;s<a;s++){const o=i[s].name||String(s);this.morphTargetInfluences.push(0),this.morphTargetDictionary[o]=s}}}}}function Ir(r,t,e,n,i,s){const a=r.geometry.attributes.position;if(Zr.fromBufferAttribute(a,i),Jr.fromBufferAttribute(a,s),e.distanceSqToSegment(Zr,Jr,Ga,Kc)>n)return;Ga.applyMatrix4(r.matrixWorld);const l=t.ray.origin.distanceTo(Ga);if(!(l<t.near||l>t.far))return{distance:l,point:Kc.clone().applyMatrix4(r.matrixWorld),index:i,face:null,faceIndex:null,barycoord:null,object:r}}const $c=new P,jc=new P;class mv extends vl{constructor(t,e){super(t,e),this.isLineSegments=!0,this.type="LineSegments"}computeLineDistances(){const t=this.geometry;if(t.index===null){const e=t.attributes.position,n=[];for(let i=0,s=e.count;i<s;i+=2)$c.fromBufferAttribute(e,i),jc.fromBufferAttribute(e,i+1),n[i]=i===0?0:n[i-1],n[i+1]=n[i]+$c.distanceTo(jc);t.setAttribute("lineDistance",new Vt(n,1))}else console.warn("THREE.LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.");return this}}class gv extends vl{constructor(t,e){super(t,e),this.isLineLoop=!0,this.type="LineLoop"}}class gu extends Tn{static get type(){return"PointsMaterial"}constructor(t){super(),this.isPointsMaterial=!0,this.color=new dt(16777215),this.map=null,this.alphaMap=null,this.size=1,this.sizeAttenuation=!0,this.fog=!0,this.setValues(t)}copy(t){return super.copy(t),this.color.copy(t.color),this.map=t.map,this.alphaMap=t.alphaMap,this.size=t.size,this.sizeAttenuation=t.sizeAttenuation,this.fog=t.fog,this}}const Zc=new It,Go=new ra,Dr=new Ln,Nr=new P;class _l extends he{constructor(t=new ye,e=new gu){super(),this.isPoints=!0,this.type="Points",this.geometry=t,this.material=e,this.updateMorphTargets()}copy(t,e){return super.copy(t,e),this.material=Array.isArray(t.material)?t.material.slice():t.material,this.geometry=t.geometry,this}raycast(t,e){const n=this.geometry,i=this.matrixWorld,s=t.params.Points.threshold,a=n.drawRange;if(n.boundingSphere===null&&n.computeBoundingSphere(),Dr.copy(n.boundingSphere),Dr.applyMatrix4(i),Dr.radius+=s,t.ray.intersectsSphere(Dr)===!1)return;Zc.copy(i).invert(),Go.copy(t.ray).applyMatrix4(Zc);const o=s/((this.scale.x+this.scale.y+this.scale.z)/3),l=o*o,c=n.index,u=n.attributes.position;if(c!==null){const d=Math.max(0,a.start),f=Math.min(c.count,a.start+a.count);for(let m=d,v=f;m<v;m++){const g=c.getX(m);Nr.fromBufferAttribute(u,g),Jc(Nr,g,l,i,t,e,this)}}else{const d=Math.max(0,a.start),f=Math.min(u.count,a.start+a.count);for(let m=d,v=f;m<v;m++)Nr.fromBufferAttribute(u,m),Jc(Nr,m,l,i,t,e,this)}}updateMorphTargets(){const e=this.geometry.morphAttributes,n=Object.keys(e);if(n.length>0){const i=e[n[0]];if(i!==void 0){this.morphTargetInfluences=[],this.morphTargetDictionary={};for(let s=0,a=i.length;s<a;s++){const o=i[s].name||String(s);this.morphTargetInfluences.push(0),this.morphTargetDictionary[o]=s}}}}}function Jc(r,t,e,n,i,s,a){const o=Go.distanceSqToPoint(r);if(o<e){const l=new P;Go.closestPointToPoint(r,l),l.applyMatrix4(n);const c=i.ray.origin.distanceTo(l);if(c<i.near||c>i.far)return;s.push({distance:c,distanceToRay:Math.sqrt(o),point:l,index:t,face:null,faceIndex:null,barycoord:null,object:a})}}class sr extends Ce{constructor(t,e,n,i,s,a,o,l,c){super(t,e,n,i,s,a,o,l,c),this.isCanvasTexture=!0,this.needsUpdate=!0}}class In{constructor(){this.type="Curve",this.arcLengthDivisions=200}getPoint(){return console.warn("THREE.Curve: .getPoint() not implemented."),null}getPointAt(t,e){const n=this.getUtoTmapping(t);return this.getPoint(n,e)}getPoints(t=5){const e=[];for(let n=0;n<=t;n++)e.push(this.getPoint(n/t));return e}getSpacedPoints(t=5){const e=[];for(let n=0;n<=t;n++)e.push(this.getPointAt(n/t));return e}getLength(){const t=this.getLengths();return t[t.length-1]}getLengths(t=this.arcLengthDivisions){if(this.cacheArcLengths&&this.cacheArcLengths.length===t+1&&!this.needsUpdate)return this.cacheArcLengths;this.needsUpdate=!1;const e=[];let n,i=this.getPoint(0),s=0;e.push(0);for(let a=1;a<=t;a++)n=this.getPoint(a/t),s+=n.distanceTo(i),e.push(s),i=n;return this.cacheArcLengths=e,e}updateArcLengths(){this.needsUpdate=!0,this.getLengths()}getUtoTmapping(t,e){const n=this.getLengths();let i=0;const s=n.length;let a;e?a=e:a=t*n[s-1];let o=0,l=s-1,c;for(;o<=l;)if(i=Math.floor(o+(l-o)/2),c=n[i]-a,c<0)o=i+1;else if(c>0)l=i-1;else{l=i;break}if(i=l,n[i]===a)return i/(s-1);const h=n[i],d=n[i+1]-h,f=(a-h)/d;return(i+f)/(s-1)}getTangent(t,e){let i=t-1e-4,s=t+1e-4;i<0&&(i=0),s>1&&(s=1);const a=this.getPoint(i),o=this.getPoint(s),l=e||(a.isVector2?new nt:new P);return l.copy(o).sub(a).normalize(),l}getTangentAt(t,e){const n=this.getUtoTmapping(t);return this.getTangent(n,e)}computeFrenetFrames(t,e){const n=new P,i=[],s=[],a=[],o=new P,l=new It;for(let f=0;f<=t;f++){const m=f/t;i[f]=this.getTangentAt(m,new P)}s[0]=new P,a[0]=new P;let c=Number.MAX_VALUE;const h=Math.abs(i[0].x),u=Math.abs(i[0].y),d=Math.abs(i[0].z);h<=c&&(c=h,n.set(1,0,0)),u<=c&&(c=u,n.set(0,1,0)),d<=c&&n.set(0,0,1),o.crossVectors(i[0],n).normalize(),s[0].crossVectors(i[0],o),a[0].crossVectors(i[0],s[0]);for(let f=1;f<=t;f++){if(s[f]=s[f-1].clone(),a[f]=a[f-1].clone(),o.crossVectors(i[f-1],i[f]),o.length()>Number.EPSILON){o.normalize();const m=Math.acos(Ae(i[f-1].dot(i[f]),-1,1));s[f].applyMatrix4(l.makeRotationAxis(o,m))}a[f].crossVectors(i[f],s[f])}if(e===!0){let f=Math.acos(Ae(s[0].dot(s[t]),-1,1));f/=t,i[0].dot(o.crossVectors(s[0],s[t]))>0&&(f=-f);for(let m=1;m<=t;m++)s[m].applyMatrix4(l.makeRotationAxis(i[m],f*m)),a[m].crossVectors(i[m],s[m])}return{tangents:i,normals:s,binormals:a}}clone(){return new this.constructor().copy(this)}copy(t){return this.arcLengthDivisions=t.arcLengthDivisions,this}toJSON(){const t={metadata:{version:4.6,type:"Curve",generator:"Curve.toJSON"}};return t.arcLengthDivisions=this.arcLengthDivisions,t.type=this.type,t}fromJSON(t){return this.arcLengthDivisions=t.arcLengthDivisions,this}}class xl extends In{constructor(t=0,e=0,n=1,i=1,s=0,a=Math.PI*2,o=!1,l=0){super(),this.isEllipseCurve=!0,this.type="EllipseCurve",this.aX=t,this.aY=e,this.xRadius=n,this.yRadius=i,this.aStartAngle=s,this.aEndAngle=a,this.aClockwise=o,this.aRotation=l}getPoint(t,e=new nt){const n=e,i=Math.PI*2;let s=this.aEndAngle-this.aStartAngle;const a=Math.abs(s)<Number.EPSILON;for(;s<0;)s+=i;for(;s>i;)s-=i;s<Number.EPSILON&&(a?s=0:s=i),this.aClockwise===!0&&!a&&(s===i?s=-i:s=s-i);const o=this.aStartAngle+t*s;let l=this.aX+this.xRadius*Math.cos(o),c=this.aY+this.yRadius*Math.sin(o);if(this.aRotation!==0){const h=Math.cos(this.aRotation),u=Math.sin(this.aRotation),d=l-this.aX,f=c-this.aY;l=d*h-f*u+this.aX,c=d*u+f*h+this.aY}return n.set(l,c)}copy(t){return super.copy(t),this.aX=t.aX,this.aY=t.aY,this.xRadius=t.xRadius,this.yRadius=t.yRadius,this.aStartAngle=t.aStartAngle,this.aEndAngle=t.aEndAngle,this.aClockwise=t.aClockwise,this.aRotation=t.aRotation,this}toJSON(){const t=super.toJSON();return t.aX=this.aX,t.aY=this.aY,t.xRadius=this.xRadius,t.yRadius=this.yRadius,t.aStartAngle=this.aStartAngle,t.aEndAngle=this.aEndAngle,t.aClockwise=this.aClockwise,t.aRotation=this.aRotation,t}fromJSON(t){return super.fromJSON(t),this.aX=t.aX,this.aY=t.aY,this.xRadius=t.xRadius,this.yRadius=t.yRadius,this.aStartAngle=t.aStartAngle,this.aEndAngle=t.aEndAngle,this.aClockwise=t.aClockwise,this.aRotation=t.aRotation,this}}class vv extends xl{constructor(t,e,n,i,s,a){super(t,e,n,n,i,s,a),this.isArcCurve=!0,this.type="ArcCurve"}}function yl(){let r=0,t=0,e=0,n=0;function i(s,a,o,l){r=s,t=o,e=-3*s+3*a-2*o-l,n=2*s-2*a+o+l}return{initCatmullRom:function(s,a,o,l,c){i(a,o,c*(o-s),c*(l-a))},initNonuniformCatmullRom:function(s,a,o,l,c,h,u){let d=(a-s)/c-(o-s)/(c+h)+(o-a)/h,f=(o-a)/h-(l-a)/(h+u)+(l-o)/u;d*=h,f*=h,i(a,o,d,f)},calc:function(s){const a=s*s,o=a*s;return r+t*s+e*a+n*o}}}const Ur=new P,Wa=new yl,Xa=new yl,qa=new yl;class _v extends In{constructor(t=[],e=!1,n="centripetal",i=.5){super(),this.isCatmullRomCurve3=!0,this.type="CatmullRomCurve3",this.points=t,this.closed=e,this.curveType=n,this.tension=i}getPoint(t,e=new P){const n=e,i=this.points,s=i.length,a=(s-(this.closed?0:1))*t;let o=Math.floor(a),l=a-o;this.closed?o+=o>0?0:(Math.floor(Math.abs(o)/s)+1)*s:l===0&&o===s-1&&(o=s-2,l=1);let c,h;this.closed||o>0?c=i[(o-1)%s]:(Ur.subVectors(i[0],i[1]).add(i[0]),c=Ur);const u=i[o%s],d=i[(o+1)%s];if(this.closed||o+2<s?h=i[(o+2)%s]:(Ur.subVectors(i[s-1],i[s-2]).add(i[s-1]),h=Ur),this.curveType==="centripetal"||this.curveType==="chordal"){const f=this.curveType==="chordal"?.5:.25;let m=Math.pow(c.distanceToSquared(u),f),v=Math.pow(u.distanceToSquared(d),f),g=Math.pow(d.distanceToSquared(h),f);v<1e-4&&(v=1),m<1e-4&&(m=v),g<1e-4&&(g=v),Wa.initNonuniformCatmullRom(c.x,u.x,d.x,h.x,m,v,g),Xa.initNonuniformCatmullRom(c.y,u.y,d.y,h.y,m,v,g),qa.initNonuniformCatmullRom(c.z,u.z,d.z,h.z,m,v,g)}else this.curveType==="catmullrom"&&(Wa.initCatmullRom(c.x,u.x,d.x,h.x,this.tension),Xa.initCatmullRom(c.y,u.y,d.y,h.y,this.tension),qa.initCatmullRom(c.z,u.z,d.z,h.z,this.tension));return n.set(Wa.calc(l),Xa.calc(l),qa.calc(l)),n}copy(t){super.copy(t),this.points=[];for(let e=0,n=t.points.length;e<n;e++){const i=t.points[e];this.points.push(i.clone())}return this.closed=t.closed,this.curveType=t.curveType,this.tension=t.tension,this}toJSON(){const t=super.toJSON();t.points=[];for(let e=0,n=this.points.length;e<n;e++){const i=this.points[e];t.points.push(i.toArray())}return t.closed=this.closed,t.curveType=this.curveType,t.tension=this.tension,t}fromJSON(t){super.fromJSON(t),this.points=[];for(let e=0,n=t.points.length;e<n;e++){const i=t.points[e];this.points.push(new P().fromArray(i))}return this.closed=t.closed,this.curveType=t.curveType,this.tension=t.tension,this}}function Qc(r,t,e,n,i){const s=(n-t)*.5,a=(i-e)*.5,o=r*r,l=r*o;return(2*e-2*n+s+a)*l+(-3*e+3*n-2*s-a)*o+s*r+e}function xv(r,t){const e=1-r;return e*e*t}function yv(r,t){return 2*(1-r)*r*t}function Mv(r,t){return r*r*t}function Ws(r,t,e,n){return xv(r,t)+yv(r,e)+Mv(r,n)}function bv(r,t){const e=1-r;return e*e*e*t}function Sv(r,t){const e=1-r;return 3*e*e*r*t}function wv(r,t){return 3*(1-r)*r*r*t}function Tv(r,t){return r*r*r*t}function Xs(r,t,e,n,i){return bv(r,t)+Sv(r,e)+wv(r,n)+Tv(r,i)}class vu extends In{constructor(t=new nt,e=new nt,n=new nt,i=new nt){super(),this.isCubicBezierCurve=!0,this.type="CubicBezierCurve",this.v0=t,this.v1=e,this.v2=n,this.v3=i}getPoint(t,e=new nt){const n=e,i=this.v0,s=this.v1,a=this.v2,o=this.v3;return n.set(Xs(t,i.x,s.x,a.x,o.x),Xs(t,i.y,s.y,a.y,o.y)),n}copy(t){return super.copy(t),this.v0.copy(t.v0),this.v1.copy(t.v1),this.v2.copy(t.v2),this.v3.copy(t.v3),this}toJSON(){const t=super.toJSON();return t.v0=this.v0.toArray(),t.v1=this.v1.toArray(),t.v2=this.v2.toArray(),t.v3=this.v3.toArray(),t}fromJSON(t){return super.fromJSON(t),this.v0.fromArray(t.v0),this.v1.fromArray(t.v1),this.v2.fromArray(t.v2),this.v3.fromArray(t.v3),this}}class Ev extends In{constructor(t=new P,e=new P,n=new P,i=new P){super(),this.isCubicBezierCurve3=!0,this.type="CubicBezierCurve3",this.v0=t,this.v1=e,this.v2=n,this.v3=i}getPoint(t,e=new P){const n=e,i=this.v0,s=this.v1,a=this.v2,o=this.v3;return n.set(Xs(t,i.x,s.x,a.x,o.x),Xs(t,i.y,s.y,a.y,o.y),Xs(t,i.z,s.z,a.z,o.z)),n}copy(t){return super.copy(t),this.v0.copy(t.v0),this.v1.copy(t.v1),this.v2.copy(t.v2),this.v3.copy(t.v3),this}toJSON(){const t=super.toJSON();return t.v0=this.v0.toArray(),t.v1=this.v1.toArray(),t.v2=this.v2.toArray(),t.v3=this.v3.toArray(),t}fromJSON(t){return super.fromJSON(t),this.v0.fromArray(t.v0),this.v1.fromArray(t.v1),this.v2.fromArray(t.v2),this.v3.fromArray(t.v3),this}}class _u extends In{constructor(t=new nt,e=new nt){super(),this.isLineCurve=!0,this.type="LineCurve",this.v1=t,this.v2=e}getPoint(t,e=new nt){const n=e;return t===1?n.copy(this.v2):(n.copy(this.v2).sub(this.v1),n.multiplyScalar(t).add(this.v1)),n}getPointAt(t,e){return this.getPoint(t,e)}getTangent(t,e=new nt){return e.subVectors(this.v2,this.v1).normalize()}getTangentAt(t,e){return this.getTangent(t,e)}copy(t){return super.copy(t),this.v1.copy(t.v1),this.v2.copy(t.v2),this}toJSON(){const t=super.toJSON();return t.v1=this.v1.toArray(),t.v2=this.v2.toArray(),t}fromJSON(t){return super.fromJSON(t),this.v1.fromArray(t.v1),this.v2.fromArray(t.v2),this}}class Av extends In{constructor(t=new P,e=new P){super(),this.isLineCurve3=!0,this.type="LineCurve3",this.v1=t,this.v2=e}getPoint(t,e=new P){const n=e;return t===1?n.copy(this.v2):(n.copy(this.v2).sub(this.v1),n.multiplyScalar(t).add(this.v1)),n}getPointAt(t,e){return this.getPoint(t,e)}getTangent(t,e=new P){return e.subVectors(this.v2,this.v1).normalize()}getTangentAt(t,e){return this.getTangent(t,e)}copy(t){return super.copy(t),this.v1.copy(t.v1),this.v2.copy(t.v2),this}toJSON(){const t=super.toJSON();return t.v1=this.v1.toArray(),t.v2=this.v2.toArray(),t}fromJSON(t){return super.fromJSON(t),this.v1.fromArray(t.v1),this.v2.fromArray(t.v2),this}}class xu extends In{constructor(t=new nt,e=new nt,n=new nt){super(),this.isQuadraticBezierCurve=!0,this.type="QuadraticBezierCurve",this.v0=t,this.v1=e,this.v2=n}getPoint(t,e=new nt){const n=e,i=this.v0,s=this.v1,a=this.v2;return n.set(Ws(t,i.x,s.x,a.x),Ws(t,i.y,s.y,a.y)),n}copy(t){return super.copy(t),this.v0.copy(t.v0),this.v1.copy(t.v1),this.v2.copy(t.v2),this}toJSON(){const t=super.toJSON();return t.v0=this.v0.toArray(),t.v1=this.v1.toArray(),t.v2=this.v2.toArray(),t}fromJSON(t){return super.fromJSON(t),this.v0.fromArray(t.v0),this.v1.fromArray(t.v1),this.v2.fromArray(t.v2),this}}class Rv extends In{constructor(t=new P,e=new P,n=new P){super(),this.isQuadraticBezierCurve3=!0,this.type="QuadraticBezierCurve3",this.v0=t,this.v1=e,this.v2=n}getPoint(t,e=new P){const n=e,i=this.v0,s=this.v1,a=this.v2;return n.set(Ws(t,i.x,s.x,a.x),Ws(t,i.y,s.y,a.y),Ws(t,i.z,s.z,a.z)),n}copy(t){return super.copy(t),this.v0.copy(t.v0),this.v1.copy(t.v1),this.v2.copy(t.v2),this}toJSON(){const t=super.toJSON();return t.v0=this.v0.toArray(),t.v1=this.v1.toArray(),t.v2=this.v2.toArray(),t}fromJSON(t){return super.fromJSON(t),this.v0.fromArray(t.v0),this.v1.fromArray(t.v1),this.v2.fromArray(t.v2),this}}class yu extends In{constructor(t=[]){super(),this.isSplineCurve=!0,this.type="SplineCurve",this.points=t}getPoint(t,e=new nt){const n=e,i=this.points,s=(i.length-1)*t,a=Math.floor(s),o=s-a,l=i[a===0?a:a-1],c=i[a],h=i[a>i.length-2?i.length-1:a+1],u=i[a>i.length-3?i.length-1:a+2];return n.set(Qc(o,l.x,c.x,h.x,u.x),Qc(o,l.y,c.y,h.y,u.y)),n}copy(t){super.copy(t),this.points=[];for(let e=0,n=t.points.length;e<n;e++){const i=t.points[e];this.points.push(i.clone())}return this}toJSON(){const t=super.toJSON();t.points=[];for(let e=0,n=this.points.length;e<n;e++){const i=this.points[e];t.points.push(i.toArray())}return t}fromJSON(t){super.fromJSON(t),this.points=[];for(let e=0,n=t.points.length;e<n;e++){const i=t.points[e];this.points.push(new nt().fromArray(i))}return this}}var th=Object.freeze({__proto__:null,ArcCurve:vv,CatmullRomCurve3:_v,CubicBezierCurve:vu,CubicBezierCurve3:Ev,EllipseCurve:xl,LineCurve:_u,LineCurve3:Av,QuadraticBezierCurve:xu,QuadraticBezierCurve3:Rv,SplineCurve:yu});class Cv extends In{constructor(){super(),this.type="CurvePath",this.curves=[],this.autoClose=!1}add(t){this.curves.push(t)}closePath(){const t=this.curves[0].getPoint(0),e=this.curves[this.curves.length-1].getPoint(1);if(!t.equals(e)){const n=t.isVector2===!0?"LineCurve":"LineCurve3";this.curves.push(new th[n](e,t))}return this}getPoint(t,e){const n=t*this.getLength(),i=this.getCurveLengths();let s=0;for(;s<i.length;){if(i[s]>=n){const a=i[s]-n,o=this.curves[s],l=o.getLength(),c=l===0?0:1-a/l;return o.getPointAt(c,e)}s++}return null}getLength(){const t=this.getCurveLengths();return t[t.length-1]}updateArcLengths(){this.needsUpdate=!0,this.cacheLengths=null,this.getCurveLengths()}getCurveLengths(){if(this.cacheLengths&&this.cacheLengths.length===this.curves.length)return this.cacheLengths;const t=[];let e=0;for(let n=0,i=this.curves.length;n<i;n++)e+=this.curves[n].getLength(),t.push(e);return this.cacheLengths=t,t}getSpacedPoints(t=40){const e=[];for(let n=0;n<=t;n++)e.push(this.getPoint(n/t));return this.autoClose&&e.push(e[0]),e}getPoints(t=12){const e=[];let n;for(let i=0,s=this.curves;i<s.length;i++){const a=s[i],o=a.isEllipseCurve?t*2:a.isLineCurve||a.isLineCurve3?1:a.isSplineCurve?t*a.points.length:t,l=a.getPoints(o);for(let c=0;c<l.length;c++){const h=l[c];n&&n.equals(h)||(e.push(h),n=h)}}return this.autoClose&&e.length>1&&!e[e.length-1].equals(e[0])&&e.push(e[0]),e}copy(t){super.copy(t),this.curves=[];for(let e=0,n=t.curves.length;e<n;e++){const i=t.curves[e];this.curves.push(i.clone())}return this.autoClose=t.autoClose,this}toJSON(){const t=super.toJSON();t.autoClose=this.autoClose,t.curves=[];for(let e=0,n=this.curves.length;e<n;e++){const i=this.curves[e];t.curves.push(i.toJSON())}return t}fromJSON(t){super.fromJSON(t),this.autoClose=t.autoClose,this.curves=[];for(let e=0,n=t.curves.length;e<n;e++){const i=t.curves[e];this.curves.push(new th[i.type]().fromJSON(i))}return this}}class Pv extends Cv{constructor(t){super(),this.type="Path",this.currentPoint=new nt,t&&this.setFromPoints(t)}setFromPoints(t){this.moveTo(t[0].x,t[0].y);for(let e=1,n=t.length;e<n;e++)this.lineTo(t[e].x,t[e].y);return this}moveTo(t,e){return this.currentPoint.set(t,e),this}lineTo(t,e){const n=new _u(this.currentPoint.clone(),new nt(t,e));return this.curves.push(n),this.currentPoint.set(t,e),this}quadraticCurveTo(t,e,n,i){const s=new xu(this.currentPoint.clone(),new nt(t,e),new nt(n,i));return this.curves.push(s),this.currentPoint.set(n,i),this}bezierCurveTo(t,e,n,i,s,a){const o=new vu(this.currentPoint.clone(),new nt(t,e),new nt(n,i),new nt(s,a));return this.curves.push(o),this.currentPoint.set(s,a),this}splineThru(t){const e=[this.currentPoint.clone()].concat(t),n=new yu(e);return this.curves.push(n),this.currentPoint.copy(t[t.length-1]),this}arc(t,e,n,i,s,a){const o=this.currentPoint.x,l=this.currentPoint.y;return this.absarc(t+o,e+l,n,i,s,a),this}absarc(t,e,n,i,s,a){return this.absellipse(t,e,n,n,i,s,a),this}ellipse(t,e,n,i,s,a,o,l){const c=this.currentPoint.x,h=this.currentPoint.y;return this.absellipse(t+c,e+h,n,i,s,a,o,l),this}absellipse(t,e,n,i,s,a,o,l){const c=new xl(t,e,n,i,s,a,o,l);if(this.curves.length>0){const u=c.getPoint(0);u.equals(this.currentPoint)||this.lineTo(u.x,u.y)}this.curves.push(c);const h=c.getPoint(1);return this.currentPoint.copy(h),this}copy(t){return super.copy(t),this.currentPoint.copy(t.currentPoint),this}toJSON(){const t=super.toJSON();return t.currentPoint=this.currentPoint.toArray(),t}fromJSON(t){return super.fromJSON(t),this.currentPoint.fromArray(t.currentPoint),this}}class Ml extends ye{constructor(t=[new nt(0,-.5),new nt(.5,0),new nt(0,.5)],e=12,n=0,i=Math.PI*2){super(),this.type="LatheGeometry",this.parameters={points:t,segments:e,phiStart:n,phiLength:i},e=Math.floor(e),i=Ae(i,0,Math.PI*2);const s=[],a=[],o=[],l=[],c=[],h=1/e,u=new P,d=new nt,f=new P,m=new P,v=new P;let g=0,p=0;for(let x=0;x<=t.length-1;x++)switch(x){case 0:g=t[x+1].x-t[x].x,p=t[x+1].y-t[x].y,f.x=p*1,f.y=-g,f.z=p*0,v.copy(f),f.normalize(),l.push(f.x,f.y,f.z);break;case t.length-1:l.push(v.x,v.y,v.z);break;default:g=t[x+1].x-t[x].x,p=t[x+1].y-t[x].y,f.x=p*1,f.y=-g,f.z=p*0,m.copy(f),f.x+=v.x,f.y+=v.y,f.z+=v.z,f.normalize(),l.push(f.x,f.y,f.z),v.copy(m)}for(let x=0;x<=e;x++){const y=n+x*h*i,_=Math.sin(y),I=Math.cos(y);for(let E=0;E<=t.length-1;E++){u.x=t[E].x*_,u.y=t[E].y,u.z=t[E].x*I,a.push(u.x,u.y,u.z),d.x=x/e,d.y=E/(t.length-1),o.push(d.x,d.y);const A=l[3*E+0]*_,C=l[3*E+1],b=l[3*E+0]*I;c.push(A,C,b)}}for(let x=0;x<e;x++)for(let y=0;y<t.length-1;y++){const _=y+x*t.length,I=_,E=_+t.length,A=_+t.length+1,C=_+1;s.push(I,E,C),s.push(A,C,E)}this.setIndex(s),this.setAttribute("position",new Vt(a,3)),this.setAttribute("uv",new Vt(o,2)),this.setAttribute("normal",new Vt(c,3))}copy(t){return super.copy(t),this.parameters=Object.assign({},t.parameters),this}static fromJSON(t){return new Ml(t.points,t.segments,t.phiStart,t.phiLength)}}class bl extends Ml{constructor(t=1,e=1,n=4,i=8){const s=new Pv;s.absarc(0,-e/2,t,Math.PI*1.5,0),s.absarc(0,e/2,t,0,Math.PI*.5),super(s.getPoints(n),i),this.type="CapsuleGeometry",this.parameters={radius:t,length:e,capSegments:n,radialSegments:i}}static fromJSON(t){return new bl(t.radius,t.length,t.capSegments,t.radialSegments)}}class la extends ye{constructor(t=1,e=32,n=0,i=Math.PI*2){super(),this.type="CircleGeometry",this.parameters={radius:t,segments:e,thetaStart:n,thetaLength:i},e=Math.max(3,e);const s=[],a=[],o=[],l=[],c=new P,h=new nt;a.push(0,0,0),o.push(0,0,1),l.push(.5,.5);for(let u=0,d=3;u<=e;u++,d+=3){const f=n+u/e*i;c.x=t*Math.cos(f),c.y=t*Math.sin(f),a.push(c.x,c.y,c.z),o.push(0,0,1),h.x=(a[d]/t+1)/2,h.y=(a[d+1]/t+1)/2,l.push(h.x,h.y)}for(let u=1;u<=e;u++)s.push(u,u+1,0);this.setIndex(s),this.setAttribute("position",new Vt(a,3)),this.setAttribute("normal",new Vt(o,3)),this.setAttribute("uv",new Vt(l,2))}copy(t){return super.copy(t),this.parameters=Object.assign({},t.parameters),this}static fromJSON(t){return new la(t.radius,t.segments,t.thetaStart,t.thetaLength)}}class Qe extends ye{constructor(t=1,e=1,n=1,i=32,s=1,a=!1,o=0,l=Math.PI*2){super(),this.type="CylinderGeometry",this.parameters={radiusTop:t,radiusBottom:e,height:n,radialSegments:i,heightSegments:s,openEnded:a,thetaStart:o,thetaLength:l};const c=this;i=Math.floor(i),s=Math.floor(s);const h=[],u=[],d=[],f=[];let m=0;const v=[],g=n/2;let p=0;x(),a===!1&&(t>0&&y(!0),e>0&&y(!1)),this.setIndex(h),this.setAttribute("position",new Vt(u,3)),this.setAttribute("normal",new Vt(d,3)),this.setAttribute("uv",new Vt(f,2));function x(){const _=new P,I=new P;let E=0;const A=(e-t)/n;for(let C=0;C<=s;C++){const b=[],M=C/s,L=M*(e-t)+t;for(let z=0;z<=i;z++){const R=z/i,B=R*l+o,j=Math.sin(B),X=Math.cos(B);I.x=L*j,I.y=-M*n+g,I.z=L*X,u.push(I.x,I.y,I.z),_.set(j,A,X).normalize(),d.push(_.x,_.y,_.z),f.push(R,1-M),b.push(m++)}v.push(b)}for(let C=0;C<i;C++)for(let b=0;b<s;b++){const M=v[b][C],L=v[b+1][C],z=v[b+1][C+1],R=v[b][C+1];(t>0||b!==0)&&(h.push(M,L,R),E+=3),(e>0||b!==s-1)&&(h.push(L,z,R),E+=3)}c.addGroup(p,E,0),p+=E}function y(_){const I=m,E=new nt,A=new P;let C=0;const b=_===!0?t:e,M=_===!0?1:-1;for(let z=1;z<=i;z++)u.push(0,g*M,0),d.push(0,M,0),f.push(.5,.5),m++;const L=m;for(let z=0;z<=i;z++){const B=z/i*l+o,j=Math.cos(B),X=Math.sin(B);A.x=b*X,A.y=g*M,A.z=b*j,u.push(A.x,A.y,A.z),d.push(0,M,0),E.x=j*.5+.5,E.y=X*.5*M+.5,f.push(E.x,E.y),m++}for(let z=0;z<i;z++){const R=I+z,B=L+z;_===!0?h.push(B,B+1,R):h.push(B+1,B,R),C+=3}c.addGroup(p,C,_===!0?1:2),p+=C}}copy(t){return super.copy(t),this.parameters=Object.assign({},t.parameters),this}static fromJSON(t){return new Qe(t.radiusTop,t.radiusBottom,t.height,t.radialSegments,t.heightSegments,t.openEnded,t.thetaStart,t.thetaLength)}}class ns extends Qe{constructor(t=1,e=1,n=32,i=1,s=!1,a=0,o=Math.PI*2){super(0,t,e,n,i,s,a,o),this.type="ConeGeometry",this.parameters={radius:t,height:e,radialSegments:n,heightSegments:i,openEnded:s,thetaStart:a,thetaLength:o}}static fromJSON(t){return new ns(t.radius,t.height,t.radialSegments,t.heightSegments,t.openEnded,t.thetaStart,t.thetaLength)}}class ca extends ye{constructor(t=[],e=[],n=1,i=0){super(),this.type="PolyhedronGeometry",this.parameters={vertices:t,indices:e,radius:n,detail:i};const s=[],a=[];o(i),c(n),h(),this.setAttribute("position",new Vt(s,3)),this.setAttribute("normal",new Vt(s.slice(),3)),this.setAttribute("uv",new Vt(a,2)),i===0?this.computeVertexNormals():this.normalizeNormals();function o(x){const y=new P,_=new P,I=new P;for(let E=0;E<e.length;E+=3)f(e[E+0],y),f(e[E+1],_),f(e[E+2],I),l(y,_,I,x)}function l(x,y,_,I){const E=I+1,A=[];for(let C=0;C<=E;C++){A[C]=[];const b=x.clone().lerp(_,C/E),M=y.clone().lerp(_,C/E),L=E-C;for(let z=0;z<=L;z++)z===0&&C===E?A[C][z]=b:A[C][z]=b.clone().lerp(M,z/L)}for(let C=0;C<E;C++)for(let b=0;b<2*(E-C)-1;b++){const M=Math.floor(b/2);b%2===0?(d(A[C][M+1]),d(A[C+1][M]),d(A[C][M])):(d(A[C][M+1]),d(A[C+1][M+1]),d(A[C+1][M]))}}function c(x){const y=new P;for(let _=0;_<s.length;_+=3)y.x=s[_+0],y.y=s[_+1],y.z=s[_+2],y.normalize().multiplyScalar(x),s[_+0]=y.x,s[_+1]=y.y,s[_+2]=y.z}function h(){const x=new P;for(let y=0;y<s.length;y+=3){x.x=s[y+0],x.y=s[y+1],x.z=s[y+2];const _=g(x)/2/Math.PI+.5,I=p(x)/Math.PI+.5;a.push(_,1-I)}m(),u()}function u(){for(let x=0;x<a.length;x+=6){const y=a[x+0],_=a[x+2],I=a[x+4],E=Math.max(y,_,I),A=Math.min(y,_,I);E>.9&&A<.1&&(y<.2&&(a[x+0]+=1),_<.2&&(a[x+2]+=1),I<.2&&(a[x+4]+=1))}}function d(x){s.push(x.x,x.y,x.z)}function f(x,y){const _=x*3;y.x=t[_+0],y.y=t[_+1],y.z=t[_+2]}function m(){const x=new P,y=new P,_=new P,I=new P,E=new nt,A=new nt,C=new nt;for(let b=0,M=0;b<s.length;b+=9,M+=6){x.set(s[b+0],s[b+1],s[b+2]),y.set(s[b+3],s[b+4],s[b+5]),_.set(s[b+6],s[b+7],s[b+8]),E.set(a[M+0],a[M+1]),A.set(a[M+2],a[M+3]),C.set(a[M+4],a[M+5]),I.copy(x).add(y).add(_).divideScalar(3);const L=g(I);v(E,M+0,x,L),v(A,M+2,y,L),v(C,M+4,_,L)}}function v(x,y,_,I){I<0&&x.x===1&&(a[y]=x.x-1),_.x===0&&_.z===0&&(a[y]=I/2/Math.PI+.5)}function g(x){return Math.atan2(x.z,-x.x)}function p(x){return Math.atan2(-x.y,Math.sqrt(x.x*x.x+x.z*x.z))}}copy(t){return super.copy(t),this.parameters=Object.assign({},t.parameters),this}static fromJSON(t){return new ca(t.vertices,t.indices,t.radius,t.details)}}class Sl extends ca{constructor(t=1,e=0){const n=(1+Math.sqrt(5))/2,i=1/n,s=[-1,-1,-1,-1,-1,1,-1,1,-1,-1,1,1,1,-1,-1,1,-1,1,1,1,-1,1,1,1,0,-i,-n,0,-i,n,0,i,-n,0,i,n,-i,-n,0,-i,n,0,i,-n,0,i,n,0,-n,0,-i,n,0,-i,-n,0,i,n,0,i],a=[3,11,7,3,7,15,3,15,13,7,19,17,7,17,6,7,6,15,17,4,8,17,8,10,17,10,6,8,0,16,8,16,2,8,2,10,0,12,1,0,1,18,0,18,16,6,10,2,6,2,13,6,13,15,2,16,18,2,18,3,2,3,13,18,1,9,18,9,11,18,11,3,4,14,12,4,12,0,4,0,8,11,9,5,11,5,19,11,19,7,19,5,14,19,14,4,19,4,17,1,12,14,1,14,5,1,5,9];super(s,a,t,e),this.type="DodecahedronGeometry",this.parameters={radius:t,detail:e}}static fromJSON(t){return new Sl(t.radius,t.detail)}}class wl extends ca{constructor(t=1,e=0){const n=[1,0,0,-1,0,0,0,1,0,0,-1,0,0,0,1,0,0,-1],i=[0,2,4,0,4,3,0,3,5,0,5,2,1,2,5,1,5,3,1,3,4,1,4,2];super(n,i,t,e),this.type="OctahedronGeometry",this.parameters={radius:t,detail:e}}static fromJSON(t){return new wl(t.radius,t.detail)}}class Fi extends ye{constructor(t=.5,e=1,n=32,i=1,s=0,a=Math.PI*2){super(),this.type="RingGeometry",this.parameters={innerRadius:t,outerRadius:e,thetaSegments:n,phiSegments:i,thetaStart:s,thetaLength:a},n=Math.max(3,n),i=Math.max(1,i);const o=[],l=[],c=[],h=[];let u=t;const d=(e-t)/i,f=new P,m=new nt;for(let v=0;v<=i;v++){for(let g=0;g<=n;g++){const p=s+g/n*a;f.x=u*Math.cos(p),f.y=u*Math.sin(p),l.push(f.x,f.y,f.z),c.push(0,0,1),m.x=(f.x/e+1)/2,m.y=(f.y/e+1)/2,h.push(m.x,m.y)}u+=d}for(let v=0;v<i;v++){const g=v*(n+1);for(let p=0;p<n;p++){const x=p+g,y=x,_=x+n+1,I=x+n+2,E=x+1;o.push(y,_,E),o.push(_,I,E)}}this.setIndex(o),this.setAttribute("position",new Vt(l,3)),this.setAttribute("normal",new Vt(c,3)),this.setAttribute("uv",new Vt(h,2))}copy(t){return super.copy(t),this.parameters=Object.assign({},t.parameters),this}static fromJSON(t){return new Fi(t.innerRadius,t.outerRadius,t.thetaSegments,t.phiSegments,t.thetaStart,t.thetaLength)}}class ys extends ye{constructor(t=1,e=32,n=16,i=0,s=Math.PI*2,a=0,o=Math.PI){super(),this.type="SphereGeometry",this.parameters={radius:t,widthSegments:e,heightSegments:n,phiStart:i,phiLength:s,thetaStart:a,thetaLength:o},e=Math.max(3,Math.floor(e)),n=Math.max(2,Math.floor(n));const l=Math.min(a+o,Math.PI);let c=0;const h=[],u=new P,d=new P,f=[],m=[],v=[],g=[];for(let p=0;p<=n;p++){const x=[],y=p/n;let _=0;p===0&&a===0?_=.5/e:p===n&&l===Math.PI&&(_=-.5/e);for(let I=0;I<=e;I++){const E=I/e;u.x=-t*Math.cos(i+E*s)*Math.sin(a+y*o),u.y=t*Math.cos(a+y*o),u.z=t*Math.sin(i+E*s)*Math.sin(a+y*o),m.push(u.x,u.y,u.z),d.copy(u).normalize(),v.push(d.x,d.y,d.z),g.push(E+_,1-y),x.push(c++)}h.push(x)}for(let p=0;p<n;p++)for(let x=0;x<e;x++){const y=h[p][x+1],_=h[p][x],I=h[p+1][x],E=h[p+1][x+1];(p!==0||a>0)&&f.push(y,_,E),(p!==n-1||l<Math.PI)&&f.push(_,I,E)}this.setIndex(f),this.setAttribute("position",new Vt(m,3)),this.setAttribute("normal",new Vt(v,3)),this.setAttribute("uv",new Vt(g,2))}copy(t){return super.copy(t),this.parameters=Object.assign({},t.parameters),this}static fromJSON(t){return new ys(t.radius,t.widthSegments,t.heightSegments,t.phiStart,t.phiLength,t.thetaStart,t.thetaLength)}}class Qr extends ye{constructor(t=1,e=.4,n=12,i=48,s=Math.PI*2){super(),this.type="TorusGeometry",this.parameters={radius:t,tube:e,radialSegments:n,tubularSegments:i,arc:s},n=Math.floor(n),i=Math.floor(i);const a=[],o=[],l=[],c=[],h=new P,u=new P,d=new P;for(let f=0;f<=n;f++)for(let m=0;m<=i;m++){const v=m/i*s,g=f/n*Math.PI*2;u.x=(t+e*Math.cos(g))*Math.cos(v),u.y=(t+e*Math.cos(g))*Math.sin(v),u.z=e*Math.sin(g),o.push(u.x,u.y,u.z),h.x=t*Math.cos(v),h.y=t*Math.sin(v),d.subVectors(u,h).normalize(),l.push(d.x,d.y,d.z),c.push(m/i),c.push(f/n)}for(let f=1;f<=n;f++)for(let m=1;m<=i;m++){const v=(i+1)*f+m-1,g=(i+1)*(f-1)+m-1,p=(i+1)*(f-1)+m,x=(i+1)*f+m;a.push(v,g,x),a.push(g,p,x)}this.setIndex(a),this.setAttribute("position",new Vt(o,3)),this.setAttribute("normal",new Vt(l,3)),this.setAttribute("uv",new Vt(c,2))}copy(t){return super.copy(t),this.parameters=Object.assign({},t.parameters),this}static fromJSON(t){return new Qr(t.radius,t.tube,t.radialSegments,t.tubularSegments,t.arc)}}class Lv extends Te{static get type(){return"RawShaderMaterial"}constructor(t){super(t),this.isRawShaderMaterial=!0}}class Tl extends Tn{static get type(){return"MeshStandardMaterial"}constructor(t){super(),this.isMeshStandardMaterial=!0,this.defines={STANDARD:""},this.color=new dt(16777215),this.roughness=1,this.metalness=0,this.map=null,this.lightMap=null,this.lightMapIntensity=1,this.aoMap=null,this.aoMapIntensity=1,this.emissive=new dt(0),this.emissiveIntensity=1,this.emissiveMap=null,this.bumpMap=null,this.bumpScale=1,this.normalMap=null,this.normalMapType=hl,this.normalScale=new nt(1,1),this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.roughnessMap=null,this.metalnessMap=null,this.alphaMap=null,this.envMap=null,this.envMapRotation=new En,this.envMapIntensity=1,this.wireframe=!1,this.wireframeLinewidth=1,this.wireframeLinecap="round",this.wireframeLinejoin="round",this.flatShading=!1,this.fog=!0,this.setValues(t)}copy(t){return super.copy(t),this.defines={STANDARD:""},this.color.copy(t.color),this.roughness=t.roughness,this.metalness=t.metalness,this.map=t.map,this.lightMap=t.lightMap,this.lightMapIntensity=t.lightMapIntensity,this.aoMap=t.aoMap,this.aoMapIntensity=t.aoMapIntensity,this.emissive.copy(t.emissive),this.emissiveMap=t.emissiveMap,this.emissiveIntensity=t.emissiveIntensity,this.bumpMap=t.bumpMap,this.bumpScale=t.bumpScale,this.normalMap=t.normalMap,this.normalMapType=t.normalMapType,this.normalScale.copy(t.normalScale),this.displacementMap=t.displacementMap,this.displacementScale=t.displacementScale,this.displacementBias=t.displacementBias,this.roughnessMap=t.roughnessMap,this.metalnessMap=t.metalnessMap,this.alphaMap=t.alphaMap,this.envMap=t.envMap,this.envMapRotation.copy(t.envMapRotation),this.envMapIntensity=t.envMapIntensity,this.wireframe=t.wireframe,this.wireframeLinewidth=t.wireframeLinewidth,this.wireframeLinecap=t.wireframeLinecap,this.wireframeLinejoin=t.wireframeLinejoin,this.flatShading=t.flatShading,this.fog=t.fog,this}}class Dn extends Tl{static get type(){return"MeshPhysicalMaterial"}constructor(t){super(),this.isMeshPhysicalMaterial=!0,this.defines={STANDARD:"",PHYSICAL:""},this.anisotropyRotation=0,this.anisotropyMap=null,this.clearcoatMap=null,this.clearcoatRoughness=0,this.clearcoatRoughnessMap=null,this.clearcoatNormalScale=new nt(1,1),this.clearcoatNormalMap=null,this.ior=1.5,Object.defineProperty(this,"reflectivity",{get:function(){return Ae(2.5*(this.ior-1)/(this.ior+1),0,1)},set:function(e){this.ior=(1+.4*e)/(1-.4*e)}}),this.iridescenceMap=null,this.iridescenceIOR=1.3,this.iridescenceThicknessRange=[100,400],this.iridescenceThicknessMap=null,this.sheenColor=new dt(0),this.sheenColorMap=null,this.sheenRoughness=1,this.sheenRoughnessMap=null,this.transmissionMap=null,this.thickness=0,this.thicknessMap=null,this.attenuationDistance=1/0,this.attenuationColor=new dt(1,1,1),this.specularIntensity=1,this.specularIntensityMap=null,this.specularColor=new dt(1,1,1),this.specularColorMap=null,this._anisotropy=0,this._clearcoat=0,this._dispersion=0,this._iridescence=0,this._sheen=0,this._transmission=0,this.setValues(t)}get anisotropy(){return this._anisotropy}set anisotropy(t){this._anisotropy>0!=t>0&&this.version++,this._anisotropy=t}get clearcoat(){return this._clearcoat}set clearcoat(t){this._clearcoat>0!=t>0&&this.version++,this._clearcoat=t}get iridescence(){return this._iridescence}set iridescence(t){this._iridescence>0!=t>0&&this.version++,this._iridescence=t}get dispersion(){return this._dispersion}set dispersion(t){this._dispersion>0!=t>0&&this.version++,this._dispersion=t}get sheen(){return this._sheen}set sheen(t){this._sheen>0!=t>0&&this.version++,this._sheen=t}get transmission(){return this._transmission}set transmission(t){this._transmission>0!=t>0&&this.version++,this._transmission=t}copy(t){return super.copy(t),this.defines={STANDARD:"",PHYSICAL:""},this.anisotropy=t.anisotropy,this.anisotropyRotation=t.anisotropyRotation,this.anisotropyMap=t.anisotropyMap,this.clearcoat=t.clearcoat,this.clearcoatMap=t.clearcoatMap,this.clearcoatRoughness=t.clearcoatRoughness,this.clearcoatRoughnessMap=t.clearcoatRoughnessMap,this.clearcoatNormalMap=t.clearcoatNormalMap,this.clearcoatNormalScale.copy(t.clearcoatNormalScale),this.dispersion=t.dispersion,this.ior=t.ior,this.iridescence=t.iridescence,this.iridescenceMap=t.iridescenceMap,this.iridescenceIOR=t.iridescenceIOR,this.iridescenceThicknessRange=[...t.iridescenceThicknessRange],this.iridescenceThicknessMap=t.iridescenceThicknessMap,this.sheen=t.sheen,this.sheenColor.copy(t.sheenColor),this.sheenColorMap=t.sheenColorMap,this.sheenRoughness=t.sheenRoughness,this.sheenRoughnessMap=t.sheenRoughnessMap,this.transmission=t.transmission,this.transmissionMap=t.transmissionMap,this.thickness=t.thickness,this.thicknessMap=t.thicknessMap,this.attenuationDistance=t.attenuationDistance,this.attenuationColor.copy(t.attenuationColor),this.specularIntensity=t.specularIntensity,this.specularIntensityMap=t.specularIntensityMap,this.specularColor.copy(t.specularColor),this.specularColorMap=t.specularColorMap,this}}class Ke extends Tn{static get type(){return"MeshLambertMaterial"}constructor(t){super(),this.isMeshLambertMaterial=!0,this.color=new dt(16777215),this.map=null,this.lightMap=null,this.lightMapIntensity=1,this.aoMap=null,this.aoMapIntensity=1,this.emissive=new dt(0),this.emissiveIntensity=1,this.emissiveMap=null,this.bumpMap=null,this.bumpScale=1,this.normalMap=null,this.normalMapType=hl,this.normalScale=new nt(1,1),this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.specularMap=null,this.alphaMap=null,this.envMap=null,this.envMapRotation=new En,this.combine=el,this.reflectivity=1,this.refractionRatio=.98,this.wireframe=!1,this.wireframeLinewidth=1,this.wireframeLinecap="round",this.wireframeLinejoin="round",this.flatShading=!1,this.fog=!0,this.setValues(t)}copy(t){return super.copy(t),this.color.copy(t.color),this.map=t.map,this.lightMap=t.lightMap,this.lightMapIntensity=t.lightMapIntensity,this.aoMap=t.aoMap,this.aoMapIntensity=t.aoMapIntensity,this.emissive.copy(t.emissive),this.emissiveMap=t.emissiveMap,this.emissiveIntensity=t.emissiveIntensity,this.bumpMap=t.bumpMap,this.bumpScale=t.bumpScale,this.normalMap=t.normalMap,this.normalMapType=t.normalMapType,this.normalScale.copy(t.normalScale),this.displacementMap=t.displacementMap,this.displacementScale=t.displacementScale,this.displacementBias=t.displacementBias,this.specularMap=t.specularMap,this.alphaMap=t.alphaMap,this.envMap=t.envMap,this.envMapRotation.copy(t.envMapRotation),this.combine=t.combine,this.reflectivity=t.reflectivity,this.refractionRatio=t.refractionRatio,this.wireframe=t.wireframe,this.wireframeLinewidth=t.wireframeLinewidth,this.wireframeLinecap=t.wireframeLinecap,this.wireframeLinejoin=t.wireframeLinejoin,this.flatShading=t.flatShading,this.fog=t.fog,this}}function Fr(r,t,e){return!r||!e&&r.constructor===t?r:typeof t.BYTES_PER_ELEMENT=="number"?new t(r):Array.prototype.slice.call(r)}function Iv(r){return ArrayBuffer.isView(r)&&!(r instanceof DataView)}function Dv(r){function t(i,s){return r[i]-r[s]}const e=r.length,n=new Array(e);for(let i=0;i!==e;++i)n[i]=i;return n.sort(t),n}function eh(r,t,e){const n=r.length,i=new r.constructor(n);for(let s=0,a=0;a!==n;++s){const o=e[s]*t;for(let l=0;l!==t;++l)i[a++]=r[o+l]}return i}function Mu(r,t,e,n){let i=1,s=r[0];for(;s!==void 0&&s[n]===void 0;)s=r[i++];if(s===void 0)return;let a=s[n];if(a!==void 0)if(Array.isArray(a))do a=s[n],a!==void 0&&(t.push(s.time),e.push.apply(e,a)),s=r[i++];while(s!==void 0);else if(a.toArray!==void 0)do a=s[n],a!==void 0&&(t.push(s.time),a.toArray(e,e.length)),s=r[i++];while(s!==void 0);else do a=s[n],a!==void 0&&(t.push(s.time),e.push(a)),s=r[i++];while(s!==void 0)}class rr{constructor(t,e,n,i){this.parameterPositions=t,this._cachedIndex=0,this.resultBuffer=i!==void 0?i:new e.constructor(n),this.sampleValues=e,this.valueSize=n,this.settings=null,this.DefaultSettings_={}}evaluate(t){const e=this.parameterPositions;let n=this._cachedIndex,i=e[n],s=e[n-1];n:{t:{let a;e:{i:if(!(t<i)){for(let o=n+2;;){if(i===void 0){if(t<s)break i;return n=e.length,this._cachedIndex=n,this.copySampleValue_(n-1)}if(n===o)break;if(s=i,i=e[++n],t<i)break t}a=e.length;break e}if(!(t>=s)){const o=e[1];t<o&&(n=2,s=o);for(let l=n-2;;){if(s===void 0)return this._cachedIndex=0,this.copySampleValue_(0);if(n===l)break;if(i=s,s=e[--n-1],t>=s)break t}a=n,n=0;break e}break n}for(;n<a;){const o=n+a>>>1;t<e[o]?a=o:n=o+1}if(i=e[n],s=e[n-1],s===void 0)return this._cachedIndex=0,this.copySampleValue_(0);if(i===void 0)return n=e.length,this._cachedIndex=n,this.copySampleValue_(n-1)}this._cachedIndex=n,this.intervalChanged_(n,s,i)}return this.interpolate_(n,s,t,i)}getSettings_(){return this.settings||this.DefaultSettings_}copySampleValue_(t){const e=this.resultBuffer,n=this.sampleValues,i=this.valueSize,s=t*i;for(let a=0;a!==i;++a)e[a]=n[s+a];return e}interpolate_(){throw new Error("call to abstract method")}intervalChanged_(){}}class Nv extends rr{constructor(t,e,n,i){super(t,e,n,i),this._weightPrev=-0,this._offsetPrev=-0,this._weightNext=-0,this._offsetNext=-0,this.DefaultSettings_={endingStart:Vl,endingEnd:Vl}}intervalChanged_(t,e,n){const i=this.parameterPositions;let s=t-2,a=t+1,o=i[s],l=i[a];if(o===void 0)switch(this.getSettings_().endingStart){case Gl:s=t,o=2*e-n;break;case Wl:s=i.length-2,o=e+i[s]-i[s+1];break;default:s=t,o=n}if(l===void 0)switch(this.getSettings_().endingEnd){case Gl:a=t,l=2*n-e;break;case Wl:a=1,l=n+i[1]-i[0];break;default:a=t-1,l=e}const c=(n-e)*.5,h=this.valueSize;this._weightPrev=c/(e-o),this._weightNext=c/(l-n),this._offsetPrev=s*h,this._offsetNext=a*h}interpolate_(t,e,n,i){const s=this.resultBuffer,a=this.sampleValues,o=this.valueSize,l=t*o,c=l-o,h=this._offsetPrev,u=this._offsetNext,d=this._weightPrev,f=this._weightNext,m=(n-e)/(i-e),v=m*m,g=v*m,p=-d*g+2*d*v-d*m,x=(1+d)*g+(-1.5-2*d)*v+(-.5+d)*m+1,y=(-1-f)*g+(1.5+f)*v+.5*m,_=f*g-f*v;for(let I=0;I!==o;++I)s[I]=p*a[h+I]+x*a[c+I]+y*a[l+I]+_*a[u+I];return s}}class Uv extends rr{constructor(t,e,n,i){super(t,e,n,i)}interpolate_(t,e,n,i){const s=this.resultBuffer,a=this.sampleValues,o=this.valueSize,l=t*o,c=l-o,h=(n-e)/(i-e),u=1-h;for(let d=0;d!==o;++d)s[d]=a[c+d]*u+a[l+d]*h;return s}}class Fv extends rr{constructor(t,e,n,i){super(t,e,n,i)}interpolate_(t){return this.copySampleValue_(t-1)}}class Nn{constructor(t,e,n,i){if(t===void 0)throw new Error("THREE.KeyframeTrack: track name is undefined");if(e===void 0||e.length===0)throw new Error("THREE.KeyframeTrack: no keyframes in track named "+t);this.name=t,this.times=Fr(e,this.TimeBufferType),this.values=Fr(n,this.ValueBufferType),this.setInterpolation(i||this.DefaultInterpolation)}static toJSON(t){const e=t.constructor;let n;if(e.toJSON!==this.toJSON)n=e.toJSON(t);else{n={name:t.name,times:Fr(t.times,Array),values:Fr(t.values,Array)};const i=t.getInterpolation();i!==t.DefaultInterpolation&&(n.interpolation=i)}return n.type=t.ValueTypeName,n}InterpolantFactoryMethodDiscrete(t){return new Fv(this.times,this.values,this.getValueSize(),t)}InterpolantFactoryMethodLinear(t){return new Uv(this.times,this.values,this.getValueSize(),t)}InterpolantFactoryMethodSmooth(t){return new Nv(this.times,this.values,this.getValueSize(),t)}setInterpolation(t){let e;switch(t){case $s:e=this.InterpolantFactoryMethodDiscrete;break;case js:e=this.InterpolantFactoryMethodLinear;break;case fa:e=this.InterpolantFactoryMethodSmooth;break}if(e===void 0){const n="unsupported interpolation for "+this.ValueTypeName+" keyframe track named "+this.name;if(this.createInterpolant===void 0)if(t!==this.DefaultInterpolation)this.setInterpolation(this.DefaultInterpolation);else throw new Error(n);return console.warn("THREE.KeyframeTrack:",n),this}return this.createInterpolant=e,this}getInterpolation(){switch(this.createInterpolant){case this.InterpolantFactoryMethodDiscrete:return $s;case this.InterpolantFactoryMethodLinear:return js;case this.InterpolantFactoryMethodSmooth:return fa}}getValueSize(){return this.values.length/this.times.length}shift(t){if(t!==0){const e=this.times;for(let n=0,i=e.length;n!==i;++n)e[n]+=t}return this}scale(t){if(t!==1){const e=this.times;for(let n=0,i=e.length;n!==i;++n)e[n]*=t}return this}trim(t,e){const n=this.times,i=n.length;let s=0,a=i-1;for(;s!==i&&n[s]<t;)++s;for(;a!==-1&&n[a]>e;)--a;if(++a,s!==0||a!==i){s>=a&&(a=Math.max(a,1),s=a-1);const o=this.getValueSize();this.times=n.slice(s,a),this.values=this.values.slice(s*o,a*o)}return this}validate(){let t=!0;const e=this.getValueSize();e-Math.floor(e)!==0&&(console.error("THREE.KeyframeTrack: Invalid value size in track.",this),t=!1);const n=this.times,i=this.values,s=n.length;s===0&&(console.error("THREE.KeyframeTrack: Track is empty.",this),t=!1);let a=null;for(let o=0;o!==s;o++){const l=n[o];if(typeof l=="number"&&isNaN(l)){console.error("THREE.KeyframeTrack: Time is not a valid number.",this,o,l),t=!1;break}if(a!==null&&a>l){console.error("THREE.KeyframeTrack: Out of order keys.",this,o,l,a),t=!1;break}a=l}if(i!==void 0&&Iv(i))for(let o=0,l=i.length;o!==l;++o){const c=i[o];if(isNaN(c)){console.error("THREE.KeyframeTrack: Value is not a valid number.",this,o,c),t=!1;break}}return t}optimize(){const t=this.times.slice(),e=this.values.slice(),n=this.getValueSize(),i=this.getInterpolation()===fa,s=t.length-1;let a=1;for(let o=1;o<s;++o){let l=!1;const c=t[o],h=t[o+1];if(c!==h&&(o!==1||c!==t[0]))if(i)l=!0;else{const u=o*n,d=u-n,f=u+n;for(let m=0;m!==n;++m){const v=e[u+m];if(v!==e[d+m]||v!==e[f+m]){l=!0;break}}}if(l){if(o!==a){t[a]=t[o];const u=o*n,d=a*n;for(let f=0;f!==n;++f)e[d+f]=e[u+f]}++a}}if(s>0){t[a]=t[s];for(let o=s*n,l=a*n,c=0;c!==n;++c)e[l+c]=e[o+c];++a}return a!==t.length?(this.times=t.slice(0,a),this.values=e.slice(0,a*n)):(this.times=t,this.values=e),this}clone(){const t=this.times.slice(),e=this.values.slice(),n=this.constructor,i=new n(this.name,t,e);return i.createInterpolant=this.createInterpolant,i}}Nn.prototype.TimeBufferType=Float32Array;Nn.prototype.ValueBufferType=Float32Array;Nn.prototype.DefaultInterpolation=js;class Ms extends Nn{constructor(t,e,n){super(t,e,n)}}Ms.prototype.ValueTypeName="bool";Ms.prototype.ValueBufferType=Array;Ms.prototype.DefaultInterpolation=$s;Ms.prototype.InterpolantFactoryMethodLinear=void 0;Ms.prototype.InterpolantFactoryMethodSmooth=void 0;class bu extends Nn{}bu.prototype.ValueTypeName="color";class fs extends Nn{}fs.prototype.ValueTypeName="number";class Ov extends rr{constructor(t,e,n,i){super(t,e,n,i)}interpolate_(t,e,n,i){const s=this.resultBuffer,a=this.sampleValues,o=this.valueSize,l=(n-e)/(i-e);let c=t*o;for(let h=c+o;c!==h;c+=4)xi.slerpFlat(s,0,a,c-o,a,c,l);return s}}class ps extends Nn{InterpolantFactoryMethodLinear(t){return new Ov(this.times,this.values,this.getValueSize(),t)}}ps.prototype.ValueTypeName="quaternion";ps.prototype.InterpolantFactoryMethodSmooth=void 0;class bs extends Nn{constructor(t,e,n){super(t,e,n)}}bs.prototype.ValueTypeName="string";bs.prototype.ValueBufferType=Array;bs.prototype.DefaultInterpolation=$s;bs.prototype.InterpolantFactoryMethodLinear=void 0;bs.prototype.InterpolantFactoryMethodSmooth=void 0;class ms extends Nn{}ms.prototype.ValueTypeName="vector";class kv{constructor(t="",e=-1,n=[],i=bd){this.name=t,this.tracks=n,this.duration=e,this.blendMode=i,this.uuid=wn(),this.duration<0&&this.resetDuration()}static parse(t){const e=[],n=t.tracks,i=1/(t.fps||1);for(let a=0,o=n.length;a!==o;++a)e.push(zv(n[a]).scale(i));const s=new this(t.name,t.duration,e,t.blendMode);return s.uuid=t.uuid,s}static toJSON(t){const e=[],n=t.tracks,i={name:t.name,duration:t.duration,tracks:e,uuid:t.uuid,blendMode:t.blendMode};for(let s=0,a=n.length;s!==a;++s)e.push(Nn.toJSON(n[s]));return i}static CreateFromMorphTargetSequence(t,e,n,i){const s=e.length,a=[];for(let o=0;o<s;o++){let l=[],c=[];l.push((o+s-1)%s,o,(o+1)%s),c.push(0,1,0);const h=Dv(l);l=eh(l,1,h),c=eh(c,1,h),!i&&l[0]===0&&(l.push(s),c.push(c[0])),a.push(new fs(".morphTargetInfluences["+e[o].name+"]",l,c).scale(1/n))}return new this(t,-1,a)}static findByName(t,e){let n=t;if(!Array.isArray(t)){const i=t;n=i.geometry&&i.geometry.animations||i.animations}for(let i=0;i<n.length;i++)if(n[i].name===e)return n[i];return null}static CreateClipsFromMorphTargetSequences(t,e,n){const i={},s=/^([\w-]*?)([\d]+)$/;for(let o=0,l=t.length;o<l;o++){const c=t[o],h=c.name.match(s);if(h&&h.length>1){const u=h[1];let d=i[u];d||(i[u]=d=[]),d.push(c)}}const a=[];for(const o in i)a.push(this.CreateFromMorphTargetSequence(o,i[o],e,n));return a}static parseAnimation(t,e){if(!t)return console.error("THREE.AnimationClip: No animation in JSONLoader data."),null;const n=function(u,d,f,m,v){if(f.length!==0){const g=[],p=[];Mu(f,g,p,m),g.length!==0&&v.push(new u(d,g,p))}},i=[],s=t.name||"default",a=t.fps||30,o=t.blendMode;let l=t.length||-1;const c=t.hierarchy||[];for(let u=0;u<c.length;u++){const d=c[u].keys;if(!(!d||d.length===0))if(d[0].morphTargets){const f={};let m;for(m=0;m<d.length;m++)if(d[m].morphTargets)for(let v=0;v<d[m].morphTargets.length;v++)f[d[m].morphTargets[v]]=-1;for(const v in f){const g=[],p=[];for(let x=0;x!==d[m].morphTargets.length;++x){const y=d[m];g.push(y.time),p.push(y.morphTarget===v?1:0)}i.push(new fs(".morphTargetInfluence["+v+"]",g,p))}l=f.length*a}else{const f=".bones["+e[u].name+"]";n(ms,f+".position",d,"pos",i),n(ps,f+".quaternion",d,"rot",i),n(ms,f+".scale",d,"scl",i)}}return i.length===0?null:new this(s,l,i,o)}resetDuration(){const t=this.tracks;let e=0;for(let n=0,i=t.length;n!==i;++n){const s=this.tracks[n];e=Math.max(e,s.times[s.times.length-1])}return this.duration=e,this}trim(){for(let t=0;t<this.tracks.length;t++)this.tracks[t].trim(0,this.duration);return this}validate(){let t=!0;for(let e=0;e<this.tracks.length;e++)t=t&&this.tracks[e].validate();return t}optimize(){for(let t=0;t<this.tracks.length;t++)this.tracks[t].optimize();return this}clone(){const t=[];for(let e=0;e<this.tracks.length;e++)t.push(this.tracks[e].clone());return new this.constructor(this.name,this.duration,t,this.blendMode)}toJSON(){return this.constructor.toJSON(this)}}function Bv(r){switch(r.toLowerCase()){case"scalar":case"double":case"float":case"number":case"integer":return fs;case"vector":case"vector2":case"vector3":case"vector4":return ms;case"color":return bu;case"quaternion":return ps;case"bool":case"boolean":return Ms;case"string":return bs}throw new Error("THREE.KeyframeTrack: Unsupported typeName: "+r)}function zv(r){if(r.type===void 0)throw new Error("THREE.KeyframeTrack: track type undefined, can not parse");const t=Bv(r.type);if(r.times===void 0){const e=[],n=[];Mu(r.keys,e,n,"value"),r.times=e,r.values=n}return t.parse!==void 0?t.parse(r):new t(r.name,r.times,r.values,r.interpolation)}const pi={enabled:!1,files:{},add:function(r,t){this.enabled!==!1&&(this.files[r]=t)},get:function(r){if(this.enabled!==!1)return this.files[r]},remove:function(r){delete this.files[r]},clear:function(){this.files={}}};class Hv{constructor(t,e,n){const i=this;let s=!1,a=0,o=0,l;const c=[];this.onStart=void 0,this.onLoad=t,this.onProgress=e,this.onError=n,this.itemStart=function(h){o++,s===!1&&i.onStart!==void 0&&i.onStart(h,a,o),s=!0},this.itemEnd=function(h){a++,i.onProgress!==void 0&&i.onProgress(h,a,o),a===o&&(s=!1,i.onLoad!==void 0&&i.onLoad())},this.itemError=function(h){i.onError!==void 0&&i.onError(h)},this.resolveURL=function(h){return l?l(h):h},this.setURLModifier=function(h){return l=h,this},this.addHandler=function(h,u){return c.push(h,u),this},this.removeHandler=function(h){const u=c.indexOf(h);return u!==-1&&c.splice(u,2),this},this.getHandler=function(h){for(let u=0,d=c.length;u<d;u+=2){const f=c[u],m=c[u+1];if(f.global&&(f.lastIndex=0),f.test(h))return m}return null}}}const Vv=new Hv;class Ss{constructor(t){this.manager=t!==void 0?t:Vv,this.crossOrigin="anonymous",this.withCredentials=!1,this.path="",this.resourcePath="",this.requestHeader={}}load(){}loadAsync(t,e){const n=this;return new Promise(function(i,s){n.load(t,i,e,s)})}parse(){}setCrossOrigin(t){return this.crossOrigin=t,this}setWithCredentials(t){return this.withCredentials=t,this}setPath(t){return this.path=t,this}setResourcePath(t){return this.resourcePath=t,this}setRequestHeader(t){return this.requestHeader=t,this}}Ss.DEFAULT_MATERIAL_NAME="__DEFAULT";const Vn={};class Gv extends Error{constructor(t,e){super(t),this.response=e}}class Su extends Ss{constructor(t){super(t)}load(t,e,n,i){t===void 0&&(t=""),this.path!==void 0&&(t=this.path+t),t=this.manager.resolveURL(t);const s=pi.get(t);if(s!==void 0)return this.manager.itemStart(t),setTimeout(()=>{e&&e(s),this.manager.itemEnd(t)},0),s;if(Vn[t]!==void 0){Vn[t].push({onLoad:e,onProgress:n,onError:i});return}Vn[t]=[],Vn[t].push({onLoad:e,onProgress:n,onError:i});const a=new Request(t,{headers:new Headers(this.requestHeader),credentials:this.withCredentials?"include":"same-origin"}),o=this.mimeType,l=this.responseType;fetch(a).then(c=>{if(c.status===200||c.status===0){if(c.status===0&&console.warn("THREE.FileLoader: HTTP Status 0 received."),typeof ReadableStream>"u"||c.body===void 0||c.body.getReader===void 0)return c;const h=Vn[t],u=c.body.getReader(),d=c.headers.get("X-File-Size")||c.headers.get("Content-Length"),f=d?parseInt(d):0,m=f!==0;let v=0;const g=new ReadableStream({start(p){x();function x(){u.read().then(({done:y,value:_})=>{if(y)p.close();else{v+=_.byteLength;const I=new ProgressEvent("progress",{lengthComputable:m,loaded:v,total:f});for(let E=0,A=h.length;E<A;E++){const C=h[E];C.onProgress&&C.onProgress(I)}p.enqueue(_),x()}},y=>{p.error(y)})}}});return new Response(g)}else throw new Gv(`fetch for "${c.url}" responded with ${c.status}: ${c.statusText}`,c)}).then(c=>{switch(l){case"arraybuffer":return c.arrayBuffer();case"blob":return c.blob();case"document":return c.text().then(h=>new DOMParser().parseFromString(h,o));case"json":return c.json();default:if(o===void 0)return c.text();{const u=/charset="?([^;"\s]*)"?/i.exec(o),d=u&&u[1]?u[1].toLowerCase():void 0,f=new TextDecoder(d);return c.arrayBuffer().then(m=>f.decode(m))}}}).then(c=>{pi.add(t,c);const h=Vn[t];delete Vn[t];for(let u=0,d=h.length;u<d;u++){const f=h[u];f.onLoad&&f.onLoad(c)}}).catch(c=>{const h=Vn[t];if(h===void 0)throw this.manager.itemError(t),c;delete Vn[t];for(let u=0,d=h.length;u<d;u++){const f=h[u];f.onError&&f.onError(c)}this.manager.itemError(t)}).finally(()=>{this.manager.itemEnd(t)}),this.manager.itemStart(t)}setResponseType(t){return this.responseType=t,this}setMimeType(t){return this.mimeType=t,this}}class Wv extends Ss{constructor(t){super(t)}load(t,e,n,i){this.path!==void 0&&(t=this.path+t),t=this.manager.resolveURL(t);const s=this,a=pi.get(t);if(a!==void 0)return s.manager.itemStart(t),setTimeout(function(){e&&e(a),s.manager.itemEnd(t)},0),a;const o=Zs("img");function l(){h(),pi.add(t,this),e&&e(this),s.manager.itemEnd(t)}function c(u){h(),i&&i(u),s.manager.itemError(t),s.manager.itemEnd(t)}function h(){o.removeEventListener("load",l,!1),o.removeEventListener("error",c,!1)}return o.addEventListener("load",l,!1),o.addEventListener("error",c,!1),t.slice(0,5)!=="data:"&&this.crossOrigin!==void 0&&(o.crossOrigin=this.crossOrigin),s.manager.itemStart(t),o.src=t,o}}class Xv extends Ss{constructor(t){super(t)}load(t,e,n,i){const s=new Ce,a=new Wv(this.manager);return a.setCrossOrigin(this.crossOrigin),a.setPath(this.path),a.load(t,function(o){s.image=o,s.needsUpdate=!0,e!==void 0&&e(s)},n,i),s}}class ha extends he{constructor(t,e=1){super(),this.isLight=!0,this.type="Light",this.color=new dt(t),this.intensity=e}dispose(){}copy(t,e){return super.copy(t,e),this.color.copy(t.color),this.intensity=t.intensity,this}toJSON(t){const e=super.toJSON(t);return e.object.color=this.color.getHex(),e.object.intensity=this.intensity,this.groundColor!==void 0&&(e.object.groundColor=this.groundColor.getHex()),this.distance!==void 0&&(e.object.distance=this.distance),this.angle!==void 0&&(e.object.angle=this.angle),this.decay!==void 0&&(e.object.decay=this.decay),this.penumbra!==void 0&&(e.object.penumbra=this.penumbra),this.shadow!==void 0&&(e.object.shadow=this.shadow.toJSON()),this.target!==void 0&&(e.object.target=this.target.uuid),e}}class qv extends ha{constructor(t,e,n){super(t,n),this.isHemisphereLight=!0,this.type="HemisphereLight",this.position.copy(he.DEFAULT_UP),this.updateMatrix(),this.groundColor=new dt(e)}copy(t,e){return super.copy(t,e),this.groundColor.copy(t.groundColor),this}}const Ya=new It,nh=new P,ih=new P;class El{constructor(t){this.camera=t,this.intensity=1,this.bias=0,this.normalBias=0,this.radius=1,this.blurSamples=8,this.mapSize=new nt(512,512),this.map=null,this.mapPass=null,this.matrix=new It,this.autoUpdate=!0,this.needsUpdate=!1,this._frustum=new dl,this._frameExtents=new nt(1,1),this._viewportCount=1,this._viewports=[new Qt(0,0,1,1)]}getViewportCount(){return this._viewportCount}getFrustum(){return this._frustum}updateMatrices(t){const e=this.camera,n=this.matrix;nh.setFromMatrixPosition(t.matrixWorld),e.position.copy(nh),ih.setFromMatrixPosition(t.target.matrixWorld),e.lookAt(ih),e.updateMatrixWorld(),Ya.multiplyMatrices(e.projectionMatrix,e.matrixWorldInverse),this._frustum.setFromProjectionMatrix(Ya),n.set(.5,0,0,.5,0,.5,0,.5,0,0,.5,.5,0,0,0,1),n.multiply(Ya)}getViewport(t){return this._viewports[t]}getFrameExtents(){return this._frameExtents}dispose(){this.map&&this.map.dispose(),this.mapPass&&this.mapPass.dispose()}copy(t){return this.camera=t.camera.clone(),this.intensity=t.intensity,this.bias=t.bias,this.radius=t.radius,this.mapSize.copy(t.mapSize),this}clone(){return new this.constructor().copy(this)}toJSON(){const t={};return this.intensity!==1&&(t.intensity=this.intensity),this.bias!==0&&(t.bias=this.bias),this.normalBias!==0&&(t.normalBias=this.normalBias),this.radius!==1&&(t.radius=this.radius),(this.mapSize.x!==512||this.mapSize.y!==512)&&(t.mapSize=this.mapSize.toArray()),t.camera=this.camera.toJSON(!1).object,delete t.camera.matrix,t}}class Yv extends El{constructor(){super(new ze(50,1,.5,500)),this.isSpotLightShadow=!0,this.focus=1}updateMatrices(t){const e=this.camera,n=us*2*t.angle*this.focus,i=this.mapSize.width/this.mapSize.height,s=t.distance||e.far;(n!==e.fov||i!==e.aspect||s!==e.far)&&(e.fov=n,e.aspect=i,e.far=s,e.updateProjectionMatrix()),super.updateMatrices(t)}copy(t){return super.copy(t),this.focus=t.focus,this}}class Kv extends ha{constructor(t,e,n=0,i=Math.PI/3,s=0,a=2){super(t,e),this.isSpotLight=!0,this.type="SpotLight",this.position.copy(he.DEFAULT_UP),this.updateMatrix(),this.target=new he,this.distance=n,this.angle=i,this.penumbra=s,this.decay=a,this.map=null,this.shadow=new Yv}get power(){return this.intensity*Math.PI}set power(t){this.intensity=t/Math.PI}dispose(){this.shadow.dispose()}copy(t,e){return super.copy(t,e),this.distance=t.distance,this.angle=t.angle,this.penumbra=t.penumbra,this.decay=t.decay,this.target=t.target.clone(),this.shadow=t.shadow.clone(),this}}const sh=new It,Ns=new P,Ka=new P;class $v extends El{constructor(){super(new ze(90,1,.5,500)),this.isPointLightShadow=!0,this._frameExtents=new nt(4,2),this._viewportCount=6,this._viewports=[new Qt(2,1,1,1),new Qt(0,1,1,1),new Qt(3,1,1,1),new Qt(1,1,1,1),new Qt(3,0,1,1),new Qt(1,0,1,1)],this._cubeDirections=[new P(1,0,0),new P(-1,0,0),new P(0,0,1),new P(0,0,-1),new P(0,1,0),new P(0,-1,0)],this._cubeUps=[new P(0,1,0),new P(0,1,0),new P(0,1,0),new P(0,1,0),new P(0,0,1),new P(0,0,-1)]}updateMatrices(t,e=0){const n=this.camera,i=this.matrix,s=t.distance||n.far;s!==n.far&&(n.far=s,n.updateProjectionMatrix()),Ns.setFromMatrixPosition(t.matrixWorld),n.position.copy(Ns),Ka.copy(n.position),Ka.add(this._cubeDirections[e]),n.up.copy(this._cubeUps[e]),n.lookAt(Ka),n.updateMatrixWorld(),i.makeTranslation(-Ns.x,-Ns.y,-Ns.z),sh.multiplyMatrices(n.projectionMatrix,n.matrixWorldInverse),this._frustum.setFromProjectionMatrix(sh)}}class jv extends ha{constructor(t,e,n=0,i=2){super(t,e),this.isPointLight=!0,this.type="PointLight",this.distance=n,this.decay=i,this.shadow=new $v}get power(){return this.intensity*4*Math.PI}set power(t){this.intensity=t/(4*Math.PI)}dispose(){this.shadow.dispose()}copy(t,e){return super.copy(t,e),this.distance=t.distance,this.decay=t.decay,this.shadow=t.shadow.clone(),this}}class Zv extends El{constructor(){super(new aa(-5,5,5,-5,.5,500)),this.isDirectionalLightShadow=!0}}class wu extends ha{constructor(t,e){super(t,e),this.isDirectionalLight=!0,this.type="DirectionalLight",this.position.copy(he.DEFAULT_UP),this.updateMatrix(),this.target=new he,this.shadow=new Zv}dispose(){this.shadow.dispose()}copy(t){return super.copy(t),this.target=t.target.clone(),this.shadow=t.shadow.clone(),this}}class qs{static decodeText(t){if(console.warn("THREE.LoaderUtils: decodeText() has been deprecated with r165 and will be removed with r175. Use TextDecoder instead."),typeof TextDecoder<"u")return new TextDecoder().decode(t);let e="";for(let n=0,i=t.length;n<i;n++)e+=String.fromCharCode(t[n]);try{return decodeURIComponent(escape(e))}catch{return e}}static extractUrlBase(t){const e=t.lastIndexOf("/");return e===-1?"./":t.slice(0,e+1)}static resolveURL(t,e){return typeof t!="string"||t===""?"":(/^https?:\/\//i.test(e)&&/^\//.test(t)&&(e=e.replace(/(^https?:\/\/[^\/]+).*/i,"$1")),/^(https?:)?\/\//i.test(t)||/^data:.*,.*$/i.test(t)||/^blob:.*$/i.test(t)?t:e+t)}}class Jv extends Ss{constructor(t){super(t),this.isImageBitmapLoader=!0,typeof createImageBitmap>"u"&&console.warn("THREE.ImageBitmapLoader: createImageBitmap() not supported."),typeof fetch>"u"&&console.warn("THREE.ImageBitmapLoader: fetch() not supported."),this.options={premultiplyAlpha:"none"}}setOptions(t){return this.options=t,this}load(t,e,n,i){t===void 0&&(t=""),this.path!==void 0&&(t=this.path+t),t=this.manager.resolveURL(t);const s=this,a=pi.get(t);if(a!==void 0){if(s.manager.itemStart(t),a.then){a.then(c=>{e&&e(c),s.manager.itemEnd(t)}).catch(c=>{i&&i(c)});return}return setTimeout(function(){e&&e(a),s.manager.itemEnd(t)},0),a}const o={};o.credentials=this.crossOrigin==="anonymous"?"same-origin":"include",o.headers=this.requestHeader;const l=fetch(t,o).then(function(c){return c.blob()}).then(function(c){return createImageBitmap(c,Object.assign(s.options,{colorSpaceConversion:"none"}))}).then(function(c){return pi.add(t,c),e&&e(c),s.manager.itemEnd(t),c}).catch(function(c){i&&i(c),pi.remove(t),s.manager.itemError(t),s.manager.itemEnd(t)});pi.add(t,l),s.manager.itemStart(t)}}class Qv{constructor(t=!0){this.autoStart=t,this.startTime=0,this.oldTime=0,this.elapsedTime=0,this.running=!1}start(){this.startTime=rh(),this.oldTime=this.startTime,this.elapsedTime=0,this.running=!0}stop(){this.getElapsedTime(),this.running=!1,this.autoStart=!1}getElapsedTime(){return this.getDelta(),this.elapsedTime}getDelta(){let t=0;if(this.autoStart&&!this.running)return this.start(),0;if(this.running){const e=rh();t=(e-this.oldTime)/1e3,this.oldTime=e,this.elapsedTime+=t}return t}}function rh(){return performance.now()}const Al="\\[\\]\\.:\\/",t_=new RegExp("["+Al+"]","g"),Rl="[^"+Al+"]",e_="[^"+Al.replace("\\.","")+"]",n_=/((?:WC+[\/:])*)/.source.replace("WC",Rl),i_=/(WCOD+)?/.source.replace("WCOD",e_),s_=/(?:\.(WC+)(?:\[(.+)\])?)?/.source.replace("WC",Rl),r_=/\.(WC+)(?:\[(.+)\])?/.source.replace("WC",Rl),a_=new RegExp("^"+n_+i_+s_+r_+"$"),o_=["material","materials","bones","map"];class l_{constructor(t,e,n){const i=n||oe.parseTrackName(e);this._targetGroup=t,this._bindings=t.subscribe_(e,i)}getValue(t,e){this.bind();const n=this._targetGroup.nCachedObjects_,i=this._bindings[n];i!==void 0&&i.getValue(t,e)}setValue(t,e){const n=this._bindings;for(let i=this._targetGroup.nCachedObjects_,s=n.length;i!==s;++i)n[i].setValue(t,e)}bind(){const t=this._bindings;for(let e=this._targetGroup.nCachedObjects_,n=t.length;e!==n;++e)t[e].bind()}unbind(){const t=this._bindings;for(let e=this._targetGroup.nCachedObjects_,n=t.length;e!==n;++e)t[e].unbind()}}class oe{constructor(t,e,n){this.path=e,this.parsedPath=n||oe.parseTrackName(e),this.node=oe.findNode(t,this.parsedPath.nodeName),this.rootNode=t,this.getValue=this._getValue_unbound,this.setValue=this._setValue_unbound}static create(t,e,n){return t&&t.isAnimationObjectGroup?new oe.Composite(t,e,n):new oe(t,e,n)}static sanitizeNodeName(t){return t.replace(/\s/g,"_").replace(t_,"")}static parseTrackName(t){const e=a_.exec(t);if(e===null)throw new Error("PropertyBinding: Cannot parse trackName: "+t);const n={nodeName:e[2],objectName:e[3],objectIndex:e[4],propertyName:e[5],propertyIndex:e[6]},i=n.nodeName&&n.nodeName.lastIndexOf(".");if(i!==void 0&&i!==-1){const s=n.nodeName.substring(i+1);o_.indexOf(s)!==-1&&(n.nodeName=n.nodeName.substring(0,i),n.objectName=s)}if(n.propertyName===null||n.propertyName.length===0)throw new Error("PropertyBinding: can not parse propertyName from trackName: "+t);return n}static findNode(t,e){if(e===void 0||e===""||e==="."||e===-1||e===t.name||e===t.uuid)return t;if(t.skeleton){const n=t.skeleton.getBoneByName(e);if(n!==void 0)return n}if(t.children){const n=function(s){for(let a=0;a<s.length;a++){const o=s[a];if(o.name===e||o.uuid===e)return o;const l=n(o.children);if(l)return l}return null},i=n(t.children);if(i)return i}return null}_getValue_unavailable(){}_setValue_unavailable(){}_getValue_direct(t,e){t[e]=this.targetObject[this.propertyName]}_getValue_array(t,e){const n=this.resolvedProperty;for(let i=0,s=n.length;i!==s;++i)t[e++]=n[i]}_getValue_arrayElement(t,e){t[e]=this.resolvedProperty[this.propertyIndex]}_getValue_toArray(t,e){this.resolvedProperty.toArray(t,e)}_setValue_direct(t,e){this.targetObject[this.propertyName]=t[e]}_setValue_direct_setNeedsUpdate(t,e){this.targetObject[this.propertyName]=t[e],this.targetObject.needsUpdate=!0}_setValue_direct_setMatrixWorldNeedsUpdate(t,e){this.targetObject[this.propertyName]=t[e],this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_array(t,e){const n=this.resolvedProperty;for(let i=0,s=n.length;i!==s;++i)n[i]=t[e++]}_setValue_array_setNeedsUpdate(t,e){const n=this.resolvedProperty;for(let i=0,s=n.length;i!==s;++i)n[i]=t[e++];this.targetObject.needsUpdate=!0}_setValue_array_setMatrixWorldNeedsUpdate(t,e){const n=this.resolvedProperty;for(let i=0,s=n.length;i!==s;++i)n[i]=t[e++];this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_arrayElement(t,e){this.resolvedProperty[this.propertyIndex]=t[e]}_setValue_arrayElement_setNeedsUpdate(t,e){this.resolvedProperty[this.propertyIndex]=t[e],this.targetObject.needsUpdate=!0}_setValue_arrayElement_setMatrixWorldNeedsUpdate(t,e){this.resolvedProperty[this.propertyIndex]=t[e],this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_fromArray(t,e){this.resolvedProperty.fromArray(t,e)}_setValue_fromArray_setNeedsUpdate(t,e){this.resolvedProperty.fromArray(t,e),this.targetObject.needsUpdate=!0}_setValue_fromArray_setMatrixWorldNeedsUpdate(t,e){this.resolvedProperty.fromArray(t,e),this.targetObject.matrixWorldNeedsUpdate=!0}_getValue_unbound(t,e){this.bind(),this.getValue(t,e)}_setValue_unbound(t,e){this.bind(),this.setValue(t,e)}bind(){let t=this.node;const e=this.parsedPath,n=e.objectName,i=e.propertyName;let s=e.propertyIndex;if(t||(t=oe.findNode(this.rootNode,e.nodeName),this.node=t),this.getValue=this._getValue_unavailable,this.setValue=this._setValue_unavailable,!t){console.warn("THREE.PropertyBinding: No target node found for track: "+this.path+".");return}if(n){let c=e.objectIndex;switch(n){case"materials":if(!t.material){console.error("THREE.PropertyBinding: Can not bind to material as node does not have a material.",this);return}if(!t.material.materials){console.error("THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.",this);return}t=t.material.materials;break;case"bones":if(!t.skeleton){console.error("THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.",this);return}t=t.skeleton.bones;for(let h=0;h<t.length;h++)if(t[h].name===c){c=h;break}break;case"map":if("map"in t){t=t.map;break}if(!t.material){console.error("THREE.PropertyBinding: Can not bind to material as node does not have a material.",this);return}if(!t.material.map){console.error("THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.",this);return}t=t.material.map;break;default:if(t[n]===void 0){console.error("THREE.PropertyBinding: Can not bind to objectName of node undefined.",this);return}t=t[n]}if(c!==void 0){if(t[c]===void 0){console.error("THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.",this,t);return}t=t[c]}}const a=t[i];if(a===void 0){const c=e.nodeName;console.error("THREE.PropertyBinding: Trying to update property for track: "+c+"."+i+" but it wasn't found.",t);return}let o=this.Versioning.None;this.targetObject=t,t.needsUpdate!==void 0?o=this.Versioning.NeedsUpdate:t.matrixWorldNeedsUpdate!==void 0&&(o=this.Versioning.MatrixWorldNeedsUpdate);let l=this.BindingType.Direct;if(s!==void 0){if(i==="morphTargetInfluences"){if(!t.geometry){console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.",this);return}if(!t.geometry.morphAttributes){console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.",this);return}t.morphTargetDictionary[s]!==void 0&&(s=t.morphTargetDictionary[s])}l=this.BindingType.ArrayElement,this.resolvedProperty=a,this.propertyIndex=s}else a.fromArray!==void 0&&a.toArray!==void 0?(l=this.BindingType.HasFromToArray,this.resolvedProperty=a):Array.isArray(a)?(l=this.BindingType.EntireArray,this.resolvedProperty=a):this.propertyName=i;this.getValue=this.GetterByBindingType[l],this.setValue=this.SetterByBindingTypeAndVersioning[l][o]}unbind(){this.node=null,this.getValue=this._getValue_unbound,this.setValue=this._setValue_unbound}}oe.Composite=l_;oe.prototype.BindingType={Direct:0,EntireArray:1,ArrayElement:2,HasFromToArray:3};oe.prototype.Versioning={None:0,NeedsUpdate:1,MatrixWorldNeedsUpdate:2};oe.prototype.GetterByBindingType=[oe.prototype._getValue_direct,oe.prototype._getValue_array,oe.prototype._getValue_arrayElement,oe.prototype._getValue_toArray];oe.prototype.SetterByBindingTypeAndVersioning=[[oe.prototype._setValue_direct,oe.prototype._setValue_direct_setNeedsUpdate,oe.prototype._setValue_direct_setMatrixWorldNeedsUpdate],[oe.prototype._setValue_array,oe.prototype._setValue_array_setNeedsUpdate,oe.prototype._setValue_array_setMatrixWorldNeedsUpdate],[oe.prototype._setValue_arrayElement,oe.prototype._setValue_arrayElement_setNeedsUpdate,oe.prototype._setValue_arrayElement_setMatrixWorldNeedsUpdate],[oe.prototype._setValue_fromArray,oe.prototype._setValue_fromArray_setNeedsUpdate,oe.prototype._setValue_fromArray_setMatrixWorldNeedsUpdate]];typeof __THREE_DEVTOOLS__<"u"&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("register",{detail:{revision:tl}}));typeof window<"u"&&(window.__THREE__?console.warn("WARNING: Multiple instances of Three.js being imported."):window.__THREE__=tl);const c_={shoot:.05,deploy:.06,gate:.07,gateBig:.12,hit:.07,unitDie:.09,enemyDie:.06,explosion:.1,cannonHit:.2,warning:.3,march:.24,bossAttack:.3},h_={neon:{root:110,scale:[0,3,5,7,10],bpm:124},desert:{root:98,scale:[0,1,4,5,7,8],bpm:112},frozen:{root:123.5,scale:[0,2,3,7,9],bpm:108},cyber:{root:116.5,scale:[0,3,5,6,7,10],bpm:132},volcanic:{root:87.3,scale:[0,1,3,6,7],bpm:120}};class u_{constructor(){this.ctx=null,this.last=new Map,this.sfxOn=!0,this.musicOn=!0,this.world=null,this.timer=0,this.nextNote=0,this.stepIndex=0,this.intensity=0}unlock(){if(!this.ctx){const t=window.AudioContext??window.webkitAudioContext;if(!t)return;try{this.ctx=new t}catch{return}const e=this.ctx;this.master=e.createGain(),this.master.gain.value=.9;const n=e.createDynamicsCompressor();n.threshold.value=-12,n.ratio.value=8,this.master.connect(n).connect(e.destination),this.sfxBus=e.createGain(),this.sfxBus.gain.value=this.sfxOn?.8:0,this.sfxBus.connect(this.master),this.musicBus=e.createGain(),this.musicBus.gain.value=this.musicOn?.34:0,this.musicBus.connect(this.master),this.noise=e.createBuffer(1,e.sampleRate,e.sampleRate);const i=this.noise.getChannelData(0);for(let s=0;s<i.length;s++)i[s]=Math.random()*2-1}this.ctx.state==="suspended"&&this.ctx.resume().catch(()=>{})}get ready(){return this.ctx?.state==="running"}setSfx(t){this.sfxOn=t,this.ctx&&this.sfxBus.gain.setTargetAtTime(t?.8:0,this.ctx.currentTime,.03)}setMusic(t){this.musicOn=t,this.ctx&&this.musicBus.gain.setTargetAtTime(t?.34:0,this.ctx.currentTime,.1)}suspend(){this.ctx?.state==="running"&&this.ctx.suspend().catch(()=>{})}resume(){this.ctx?.state==="suspended"&&this.ctx.resume().catch(()=>{}),this.ctx&&(this.nextNote=this.ctx.currentTime+.1)}tone(t,e,n,i,s,a=0,o){const l=this.ctx,c=l.currentTime+a,h=l.createOscillator(),u=l.createGain();h.type=t,h.frequency.setValueAtTime(e,c),n!==e&&h.frequency.exponentialRampToValueAtTime(Math.max(20,n),c+i),u.gain.setValueAtTime(1e-4,c),u.gain.exponentialRampToValueAtTime(s,c+.008),u.gain.exponentialRampToValueAtTime(1e-4,c+i),h.connect(u).connect(o??this.sfxBus),h.start(c),h.stop(c+i+.02)}burst(t,e,n,i,s=0,a="lowpass",o){const l=this.ctx,c=l.currentTime+s,h=l.createBufferSource();h.buffer=this.noise,h.loop=!0;const u=l.createBiquadFilter();u.type=a,u.frequency.setValueAtTime(n,c),u.frequency.exponentialRampToValueAtTime(Math.max(30,i),c+t);const d=l.createGain();d.gain.setValueAtTime(e,c),d.gain.exponentialRampToValueAtTime(1e-4,c+t),h.connect(u).connect(d).connect(o??this.sfxBus),h.start(c,Math.random()),h.stop(c+t+.02)}play(t,e=1){const n=this.ctx;if(!n||n.state!=="running"||!this.sfxOn)return;const i=c_[t];if(i){const a=this.last.get(t)??-1;if(n.currentTime-a<i)return;this.last.set(t,n.currentTime)}const s=e*(.96+Math.random()*.08);switch(t){case"shoot":this.tone("square",520*s,180*s,.09,.12),this.burst(.05,.1,5e3,900);break;case"deploy":this.tone("sine",300*s,620*s,.07,.1);break;case"gate":this.tone("triangle",660*s,990*s,.12,.16),this.tone("sine",1320*s,1320*s,.1,.06,.04);break;case"gateBig":[0,4,7,12,16].forEach((a,o)=>this.tone("triangle",440*s*Math.pow(2,a/12),440*s*Math.pow(2,a/12),.16,.14,o*.045));break;case"hit":this.burst(.05,.14,2600,500);break;case"unitDie":this.tone("square",300*s,90*s,.12,.07);break;case"enemyDie":this.burst(.11,.18,1800,220),this.tone("sawtooth",200*s,60,.12,.08);break;case"explosion":this.burst(.5,.5,900,50),this.tone("sine",120,34,.42,.5);break;case"bossRoar":this.tone("sawtooth",90,46,1.1,.34),this.tone("sawtooth",135,60,1,.2),this.burst(.9,.2,500,120);break;case"bossAttack":this.tone("sawtooth",160*s,70,.34,.22),this.burst(.22,.14,1200,200);break;case"bossDie":for(let a=0;a<5;a++)this.burst(.5,.4,1e3,60,a*.32),this.tone("sine",140-a*16,30,.4,.4,a*.32);break;case"cannonHit":this.burst(.2,.36,700,90),this.tone("square",150,60,.2,.2);break;case"victory":[0,4,7,12,7,12,16].forEach((a,o)=>this.tone("triangle",523.25*Math.pow(2,a/12),523.25*Math.pow(2,a/12),o===6?.7:.18,.2,o*.13));break;case"defeat":[0,-2,-5,-9].forEach((a,o)=>this.tone("sawtooth",220*Math.pow(2,a/12),210*Math.pow(2,a/12),.36,.14,o*.24));break;case"click":this.tone("sine",880,660,.05,.12);break;case"buy":this.tone("triangle",660,660,.08,.16),this.tone("triangle",990,990,.14,.16,.08);break;case"deny":this.tone("square",170,140,.14,.1);break;case"ability":this.tone("sawtooth",220,880,.3,.16),this.burst(.3,.12,400,6e3,0,"bandpass");break;case"warning":this.tone("square",740,740,.07,.07),this.tone("square",740,740,.07,.07,.12);break;case"march":this.burst(.05,.05,500,160);break}}setIntensity(t){this.intensity=t}startMusic(t){this.world=t,this.stepIndex=0,this.ctx&&(this.nextNote=this.ctx.currentTime+.1),this.timer||(this.timer=window.setInterval(()=>this.schedule(),60))}stopMusic(){window.clearInterval(this.timer),this.timer=0}schedule(){const t=this.ctx;if(!t||t.state!=="running"||!this.world||!this.musicOn)return;const e=h_[this.world],n=60/e.bpm/4;for(this.nextNote<t.currentTime&&(this.nextNote=t.currentTime+.05);this.nextNote<t.currentTime+.18;){const i=this.nextNote-t.currentTime,s=this.stepIndex%16,a=Math.floor(this.stepIndex/16),o=(c,h)=>{const u=e.scale,d=(c%u.length+u.length)%u.length;return e.root*Math.pow(2,h+(u[d]+12*Math.floor(c/u.length))/12)},l=[0,0,3,2][a%4];if(s%4===0&&this.tone("sine",150,42,.16,.9,i,this.musicBus),(s%2===1||this.intensity>.5)&&this.burst(.03,s%4===2?.2:.09,9e3,6e3,i,"highpass",this.musicBus),s%8===4&&this.burst(.1,.3,2400,700,i,"bandpass",this.musicBus),[0,3,6,8,11,14].includes(s)&&this.tone("sawtooth",o(l,-1),o(l,-1),n*1.6,.34,i,this.musicBus),s%2===0){const c=[0,2,4,2,5,4,2,1][(s/2+a)%8];this.tone("triangle",o(l+c,1),o(l+c,1),n*1.2,.16,i,this.musicBus)}if(this.intensity>.5&&s%4===2){const c=[4,5,7,5][a%4];this.tone("square",o(l+c,2),o(l+c,2),n*2,.07,i,this.musicBus)}this.nextNote+=n,this.stepIndex++}}}const qt=5,ts=1/60,tr=600,Be=320,er=5e3,Tu=24,Eu=17,$a=9,Au=3.4,ah=100,d_=24,f_=6.5,p_=17,xt={Muzzle:0,PodLand:1,PodHit:2,UnitDie:3,UnitFall:4,EnemyHit:5,EnemyDie:6,GateAdd:7,GateMul:8,GateCapped:9,Explosion:10,BossHit:11,BossAttack:12,BossDie:13,CannonHit:14,Impact:15,BossIntro:16,Collapse:17,TurretShot:18,Ability:19,BossShield:20,Victory:21,Summon:22,GateLoss:23},ui=class ui{constructor(){this.type=new Uint8Array(ui.CAP),this.x=new Float32Array(ui.CAP),this.z=new Float32Array(ui.CAP),this.a=new Float32Array(ui.CAP),this.n=0}push(t,e,n,i=0){if(this.n>=ui.CAP)return;const s=this.n++;this.type[s]=t,this.x[s]=e,this.z[s]=n,this.a[s]=i}clear(){this.n=0}};ui.CAP=256;let Wo=ui;function cn(r,t,e){return r<t?t:r>e?e:r}const Zt={Dead:0,Run:1,Fight:2,Fall:3,Die:4,Cheer:5};class m_{constructor(t,e=tr){this.rng=t,this.count=0,this.alive=0,this.unitHp=10,this.unitCap=er,this.lost=0,this.cursor=0,this.cap=e,this.x=new Float32Array(e),this.z=new Float32Array(e),this.pz=new Float32Array(e),this.str=new Int32Array(e),this.hp=new Float32Array(e),this.state=new Uint8Array(e),this.t=new Float32Array(e),this.speed=new Float32Array(e),this.seedX=new Float32Array(e),this.seedZ=new Float32Array(e),this.phase=new Float32Array(e),this.tx=new Float32Array(e).fill(NaN),this.tz=new Float32Array(e),this.free=new Int32Array(e);for(let n=0;n<e;n++)this.free[n]=e-1-n;this.nFree=e}isActive(t){const e=this.state[t];return e===Zt.Run||e===Zt.Fight}spawn(t,e,n){if(this.nFree===0)return-1;const i=this.free[--this.nFree];return this.x[i]=cn(t,-qt+.3,qt-.3),this.z[i]=e,this.pz[i]=e,this.str[i]=n,this.hp[i]=n*this.unitHp,this.state[i]=Zt.Run,this.t[i]=0,this.speed[i]=0,this.seedX[i]=this.rng.range(-1,1),this.seedZ[i]=this.rng.next(),this.phase[i]=this.rng.range(0,Math.PI*2),this.tx[i]=NaN,this.alive++,this.count+=n,i}anyActive(){for(let t=0;t<this.cap;t++)if(this.cursor=(this.cursor+1)%this.cap,this.isActive(this.cursor))return this.cursor;return-1}add(t,e,n,i=Tu,s=-1){const a=Math.min(Math.floor(n),this.unitCap-this.count);if(a<=0)return 0;const o=Math.min(a,i,this.nFree);if(o===0){const h=s>=0&&this.isActive(s)?s:this.anyActive();return h<0?0:(this.str[h]+=a,this.hp[h]+=a*this.unitHp,this.count+=a,a)}const l=Math.floor(a/o),c=a-l*o;for(let h=0;h<o;h++){const u=o>1?this.rng.range(-.9,.9):0,d=o>1?this.rng.range(0,1.2):0;this.spawn(t+u,e+d,l+(h<c?1:0))}return a}damage(t,e,n){if(!this.isActive(t))return 0;if(this.hp[t]-=e,this.hp[t]<=0){const a=this.str[t];return this.kill(t,Zt.Die,n),a}const i=Math.ceil(this.hp[t]/this.unitHp),s=this.str[t]-i;return s>0&&(this.str[t]=i,this.count-=s,this.lost+=s,n.push(xt.UnitDie,this.x[t],this.z[t],0)),s}removeUnits(t,e,n){if(!this.isActive(t)||e<=0)return 0;const i=this.str[t];return e>=i?(this.kill(t,Zt.Die,n),i):(this.str[t]=i-e,this.hp[t]=Math.min(this.hp[t],(i-e)*this.unitHp),this.count-=e,this.lost+=e,e)}removeAny(t,e,n){let i=e-this.removeUnits(t,e,n);for(;i>0;){const s=this.anyActive();if(s<0)break;i-=this.removeUnits(s,i,n)}return e-i}kill(t,e,n){this.isActive(t)&&(this.count-=this.str[t],this.lost+=this.str[t],this.alive--,this.state[t]=e,this.t[t]=0,this.tx[t]=NaN,n.push(e===Zt.Fall?xt.UnitFall:xt.UnitDie,this.x[t],this.z[t],1))}cheer(){for(let t=0;t<this.cap;t++)this.isActive(t)&&(this.state[t]=Zt.Cheer,this.t[t]=0)}spread(){return cn(.8+Math.sqrt(this.alive)*.2,.8,qt-.6)}update(t,e,n,i,s){const a=this.spread(),o=Math.min(12,1.5+Math.sqrt(this.alive)*.45),l=cn(e,-(qt-.4-a),qt-.4-a),c=Math.min(n+Eu,i);for(let h=0;h<this.cap;h++){const u=this.state[h];if(u===Zt.Dead)continue;if(this.t[h]+=t,this.pz[h]=this.z[h],u===Zt.Fall||u===Zt.Die){this.t[h]>.7&&(this.state[h]=Zt.Dead,this.free[this.nFree++]=h);continue}if(u!==Zt.Run){this.speed[h]=0;continue}let d=this.x[h],f=this.z[h];const m=this.tx[h];if(m===m){const v=m-d,g=this.tz[h]-f,p=Math.hypot(v,g)||1,x=Math.min(p,$a*t);d+=v/p*x,f+=g/p*x,this.speed[h]=$a}else{let v=l+this.seedX[h]*a;for(let x=0;x<s.length;x++){const y=s[x];f>y.z0-8&&f<y.z1&&e>=y.x0&&e<=y.x1&&(v=cn(v,y.x0+.4,y.x1-.4))}d+=cn((v-d)*3,-5,5)*t;const g=c-this.seedZ[h]*o,p=Math.min(Math.max(0,g-f),$a*t);f+=p,this.speed[h]=p/t}this.x[h]=cn(d,-qt+.3,qt-.3),this.z[h]=f}}}function Ru(r){return r<=1?1:Math.min(2.6,1+.28*Math.log2(r))}const Jt={Dormant:0,Intro:1,Fight:2,Dying:3,Dead:4},ta={titan:{name:"Iron Titan",radius:2.3,meleeDps:9,interval:3.4,cycle:["slam","boulder","stomp","slam","boulder"]},inferno:{name:"Inferno Guardian",radius:2.7,meleeDps:11,interval:3.1,cycle:["flame","fireball","summon","flame","fireball"]},void:{name:"Void Commander",radius:2,meleeDps:12,interval:2.8,cycle:["orbs","beam","blink","orbs","summon","beam"]}},Cu=2.6,Pu=2.4,g_=50,v_=12;class __{constructor(t,e,n){this.rng=n,this.x=0,this.state=Jt.Dormant,this.t=0,this.flash=0,this.shield=0,this.shieldMax=0,this.shieldT=0,this.attackers=0,this.attackersPrev=0,this.attack=null,this.attackT=99,this.casts=0,this.telegraphs=[],this.cannonDamage=0,this.step=0,this.kind=t.kind,this.tier=t.tier,this.stats=ta[t.kind],this.z=e,this.hp=this.maxHp=t.hp,this.cooldown=2;for(let i=0;i<v_;i++)this.telegraphs.push({live:!1,shape:0,x:0,z:0,hw:0,hd:0,t:0,delay:1,cannonDmg:0})}get targetable(){return this.state===Jt.Fight}get overloaded(){return this.state===Jt.Fight&&this.t>g_}get enraged(){return this.hp<this.maxHp*.3}hit(t,e){if(!(!this.targetable||t<=0)){if(this.shield>0){this.shield-=t,this.shield<=0&&(this.shield=0,e.push(xt.BossShield,this.x,this.z,0));return}if(this.hp-=t,this.flash<.05&&(this.flash=1),this.hp<=0){this.hp=0,this.state=Jt.Dying,this.t=0;for(const n of this.telegraphs)n.live=!1;e.push(xt.BossDie,this.x,this.z)}}}podHit(t,e,n,i){return!this.targetable||Math.hypot(t-this.x,e-this.z)>this.stats.radius+.3?!1:(this.hit(n,i),i.push(xt.BossHit,t,e),!0)}warn(t,e,n,i,s,a,o){for(const l of this.telegraphs)if(!l.live){l.live=!0,l.shape=t,l.x=e,l.z=n,l.hw=i,l.hd=s,l.t=0,l.delay=a,l.cannonDmg=o*(.85+.15*this.tier);return}}cast(t,e,n,i,s,a){this.attack=t,this.attackT=0,this.casts++,a.push(xt.BossAttack,this.x,this.z,this.casts);const o=qt-.4;switch(t){case"slam":{let l=this.x,c=this.z-5;for(let h=0;h<12;h++){const u=this.rng.int(0,i.cap-1);if(i.isActive(u)&&this.z-i.z[u]<16){l=i.x[u],c=i.z[u];break}}this.warn(0,l,c,2.6,2.6,1.3,0);break}case"boulder":this.warn(0,e,n,1.9,1.9,1.5,20);break;case"stomp":this.warn(1,-o/2,this.z-5.5,o/2,1.5,1.1,0),this.warn(1,o/2,this.z-10,o/2,1.5,1.7,0);break;case"flame":{const l=this.rng.next()<.5?-1:1;this.warn(1,l*(o/2),this.z-9.5,o/2,8,1.5,0);break}case"fireball":{const l=this.rng.next()<.5?-2.6:2.6;this.warn(0,e,n,1.8,1.8,1.4,18),this.warn(0,cn(e+l,-o,o),n,1.8,1.8,1.9,18);break}case"orbs":for(let l=0;l<3;l++)this.warn(0,cn(e+(l-1)*this.rng.range(1.8,2.8),-o,o),n,1.6,1.6,1.2+l*.45,16);break;case"beam":{const l=(this.z-n)/2;this.warn(1,this.x,this.z-l,1.4,l,1.4,24);break}case"blink":{const l=[-3,0,3].filter(c=>Math.abs(c-this.x)>1);this.x=this.rng.pick(l),this.shieldMax=this.shield=this.maxHp*.1,this.shieldT=8,a.push(xt.BossShield,this.x,this.z,1);break}case"summon":{const l=4+Math.round(this.tier*2);for(let c=0;c<l;c++){const h=((c+.5)/l-.5)*2*(o-.5);s.spawn(this.kind==="void"&&c%3===0?"brute":"grunt",h,this.z-3.5-c%2,!0)}a.push(xt.Summon,this.x,this.z-3.5);break}}}land(t,e,n,i,s){s.push(xt.Explosion,t.x,t.z,t.shape===0?t.hw:Math.min(t.hw,t.hd)+1);const a=(o,l,c)=>t.shape===0?Math.hypot(o-t.x,l-t.z)<t.hw+c:Math.abs(o-t.x)<t.hw+c&&Math.abs(l-t.z)<t.hd+c;for(let o=0;o<i.cap;o++)i.isActive(o)&&a(i.x[o],i.z[o],0)&&i.kill(o,Zt.Die,s);t.cannonDmg>0&&a(e,n,.5)&&(this.cannonDamage+=t.cannonDmg)}update(t,e,n,i,s,a){switch(this.t+=t,this.attackT+=t,this.cannonDamage=0,this.flash>0&&(this.flash=Math.max(0,this.flash-t*5)),this.attackersPrev=this.attackers,this.attackers=0,this.state){case Jt.Dormant:this.z-n<34&&(this.state=Jt.Intro,this.t=0,a.push(xt.BossIntro,this.x,this.z));return;case Jt.Intro:this.t>=Cu&&(this.state=Jt.Fight,this.t=0);return;case Jt.Dying:this.t>=Pu&&(this.state=Jt.Dead);return;case Jt.Dead:return}if(this.shield>0&&(this.shieldT-=t,this.shieldT<=0&&(this.shield=0)),this.cooldown-=t,this.cooldown<=0){const o=this.stats.cycle;this.cast(o[this.step++%o.length],e,n,i,s,a),this.overloaded&&(this.cannonDamage+=9*this.tier,a.push(xt.Explosion,e,n,2)),this.cooldown=this.stats.interval/(.85+.15*this.tier)*(this.enraged?.7:1)}for(const o of this.telegraphs)o.live&&(o.t+=t,o.t>=o.delay&&(o.live=!1,this.land(o,e,n,i,a)))}}class ea{constructor(t){this.s=t>>>0||1}next(){let t=this.s+=1831565813;return t=Math.imul(t^t>>>15,t|1),t^=t+Math.imul(t^t>>>7,t|61),((t^t>>>14)>>>0)/4294967296}range(t,e){return t+(e-t)*this.next()}int(t,e){return Math.floor(this.range(t,e+1))}pick(t){return t[Math.floor(this.next()*t.length)]}}const x_=4,y_=3;class M_{constructor(t){this.stats=t,this.x=0,this.z=0,this.hp=ah,this.maxHp=ah,this.recoil=0,this.overdrive=0,this.abilityCd=0,this.blocked=!1,this.hurt=0,this.shots=0,this.shield=0,this.fireT=.4}update(t,e,n,i,s,a){const o=qt-.9;Number.isFinite(e)||(e=e>0?o:e<0?-o:this.x),this.x+=(cn(e,-o,o)-this.x)*Math.min(1,t*20);const l=Math.min(i,s-6);this.blocked=this.z>=l,this.blocked||(this.z=Math.min(l,this.z+Au*t)),this.abilityCd>0&&(this.abilityCd=Math.max(0,this.abilityCd-t)),this.overdrive>0&&(this.overdrive=Math.max(0,this.overdrive-t)),n&&this.abilityCd<=0&&(this.overdrive=x_,this.abilityCd=this.stats.abilityCooldown,a.push(xt.Ability,this.x,this.z)),this.recoil>0&&(this.recoil=Math.max(0,this.recoil-t*9)),this.hurt>0&&(this.hurt=Math.max(0,this.hurt-t*3)),this.shield>0&&(this.shield=Math.max(0,this.shield-t));let c=0;this.fireT-=t;const h=1/(this.stats.fireRate*(this.overdrive>0?y_:1));for(;this.fireT<=0;)this.fireT+=h,c++;return c>0&&(this.recoil=1,this.shots+=c,a.push(xt.Muzzle,this.x,this.z+1.8)),c}takeDamage(t,e){t<=0||this.hp<=0||this.shield>0||(this.hp=Math.max(0,this.hp-t),this.hurt<.4&&e.push(xt.CannonHit,this.x,this.z,t),this.hurt=1)}}const _e={Dead:0,Idle:1,March:2,Fight:3,Dying:4},oh={grunt:0,brute:1,giant:2,turret:3},Di=[{hp:11,dps:4,speed:2.8,radius:.34,score:7,scale:1},{hp:80,dps:16,speed:2,radius:.55,score:30,scale:1.25},{hp:420,dps:40,speed:1.4,radius:1.25,score:120,scale:2.7},{hp:130,dps:18,speed:0,radius:.75,score:50,scale:1}],b_=30,ja=15,lh=1.5,an=24;class S_{constructor(t,e=1,n=1){this.rng=t,this.hpScale=e,this.dmgScale=n,this.cap=Be,this.x=new Float32Array(Be),this.z=new Float32Array(Be),this.hp=new Float32Array(Be),this.maxHp=new Float32Array(Be),this.dps=new Float32Array(Be),this.kind=new Uint8Array(Be),this.state=new Uint8Array(Be),this.t=new Float32Array(Be),this.flash=new Float32Array(Be),this.phase=new Float32Array(Be),this.attackers=new Uint16Array(Be),this.attackersPrev=new Uint16Array(Be),this.cd=new Float32Array(Be),this.boltX=new Float32Array(an),this.boltZ=new Float32Array(an),this.boltSX=new Float32Array(an),this.boltSZ=new Float32Array(an),this.boltTX=new Float32Array(an),this.boltTZ=new Float32Array(an),this.boltT=new Float32Array(an),this.boltDmg=new Float32Array(an),this.boltLive=new Uint8Array(an),this.boltCap=an,this.alive=0,this.killed=0,this.score=0,this.blockerZ=1/0,this.cannonDamage=0,this.nextWave=0,this.waves=[]}setWaves(t){this.waves=[...t].sort((e,n)=>e.z-n.z),this.nextWave=0}spawn(t,e,n,i=!1){for(let s=0;s<this.cap;s++){if(this.state[s]!==_e.Dead)continue;const a=oh[t],o=Di[a];return this.x[s]=cn(e,-qt+o.radius,qt-o.radius),this.z[s]=n,this.kind[s]=a,this.hp[s]=this.maxHp[s]=o.hp*this.hpScale,this.dps[s]=o.dps*this.dmgScale,this.state[s]=i&&o.speed>0?_e.March:_e.Idle,this.t[s]=0,this.flash[s]=0,this.attackers[s]=this.attackersPrev[s]=0,this.phase[s]=this.rng.range(0,Math.PI*2),this.cd[s]=this.rng.range(.5,lh),this.alive++,s}return-1}spawnWave(t){if(this.cap-this.alive<t.count+8&&this.alive>0)return!1;const n=Di[oh[t.kind]].radius*2.5,i=Math.max(1,Math.min(Math.ceil(Math.sqrt(t.count*1.8)),Math.floor((qt*2-1)/n)));for(let s=0;s<t.count;s++){const a=s%i,o=Math.floor(s/i),l=Math.min(i,t.count-o*i);this.spawn(t.kind,t.x+(a-(l-1)/2)*n,t.z+o*n)}return!0}isAlive(t){const e=this.state[t];return e===_e.Idle||e===_e.March||e===_e.Fight}hit(t,e,n){return!this.isAlive(t)||(this.hp[t]-=e,this.flash[t]<.05&&(this.flash[t]=1),this.hp[t]>0)?!1:(this.state[t]=_e.Dying,this.t[t]=0,this.alive--,this.killed++,this.score+=Di[this.kind[t]].score,n.push(xt.EnemyDie,this.x[t],this.z[t],this.kind[t]),!0)}killAll(t){for(let e=0;e<this.cap;e++)this.isAlive(e)&&this.hit(e,1/0,t)}update(t,e,n,i,s,a){for(;this.nextWave<this.waves.length&&this.waves[this.nextWave].z<n+62&&this.spawnWave(this.waves[this.nextWave]);)this.nextWave++;this.blockerZ=1/0,this.cannonDamage=0;for(let o=0;o<this.cap;o++){const l=this.state[o];if(l===_e.Dead)continue;if(this.t[o]+=t,this.flash[o]>0&&(this.flash[o]=Math.max(0,this.flash[o]-t*6)),l===_e.Dying){this.t[o]>.6&&(this.state[o]=_e.Dead);continue}const c=this.kind[o],h=Di[c],u=this.attackers[o]>0;this.attackersPrev[o]=this.attackers[o],this.attackers[o]=0;const d=this.z[o]-n;if(c===3){d<9&&(this.blockerZ=Math.min(this.blockerZ,this.z[o]+1.5)),this.cd[o]-=t,this.cd[o]<=0&&d<ja+4&&(this.cd[o]=lh,this.fireBolt(o,e,n,i,a));continue}if(l===_e.Idle&&d<b_&&(this.state[o]=_e.March),this.state[o]!==_e.Idle){if(d<=1.5){this.state[o]=_e.Fight,this.cannonDamage+=this.dps[o]*.4*t,this.blockerZ=Math.min(this.blockerZ,this.z[o]);continue}if(this.state[o]=u?_e.Fight:_e.March,!u){this.z[o]-=h.speed*t;let f=this.x[o];for(let m=0;m<s.length;m++){const v=s[m];this.z[o]>v.z0-1&&this.z[o]<v.z1+6&&(f=cn(f,v.x0+h.radius,v.x1-h.radius))}this.x[o]+=cn((f-this.x[o])*4,-3,3)*t}d<11&&(this.blockerZ=Math.min(this.blockerZ,this.z[o]))}}this.updateBolts(t,e,n,i,a)}fireBolt(t,e,n,i,s){let a=NaN,o=0;for(let l=0;l<10;l++){const c=this.rng.int(0,i.cap-1);if(i.isActive(c)&&!(Math.hypot(i.x[c]-this.x[t],i.z[c]-this.z[t])>ja)){a=i.x[c],o=i.z[c];break}}if(a!==a){if(this.z[t]-n>ja)return;a=e,o=n}for(let l=0;l<an;l++)if(!this.boltLive[l]){this.boltLive[l]=1,this.boltSX[l]=this.boltX[l]=this.x[t],this.boltSZ[l]=this.boltZ[l]=this.z[t],this.boltTX[l]=a,this.boltTZ[l]=o,this.boltT[l]=0,this.boltDmg[l]=this.dps[t],s.push(xt.TurretShot,this.x[t],this.z[t]);return}}updateBolts(t,e,n,i,s){for(let a=0;a<an;a++){if(!this.boltLive[a])continue;const o=Math.hypot(this.boltTX[a]-this.boltSX[a],this.boltTZ[a]-this.boltSZ[a]);this.boltT[a]+=t*16/Math.max(1,o);const l=Math.min(1,this.boltT[a]);if(this.boltX[a]=this.boltSX[a]+(this.boltTX[a]-this.boltSX[a])*l,this.boltZ[a]=this.boltSZ[a]+(this.boltTZ[a]-this.boltSZ[a])*l,l<1)continue;this.boltLive[a]=0;const c=this.boltX[a],h=this.boltZ[a];s.push(xt.Impact,c,h);for(let u=0;u<i.cap;u++){if(!i.isActive(u))continue;const d=i.x[u]-c,f=i.z[u]-h;d*d+f*f<1.2&&i.damage(u,this.boltDmg[a],s)}Math.abs(e-c)<1.2&&Math.abs(n-h)<1.2&&(this.cannonDamage+=this.boltDmg[a]*.25)}}}const w_=8,T_=22,Lu=36;function ch(r,t,e){return r*t*e}function hh(r,t,e){return r*e/Math.sqrt(Math.max(1,t))}function E_(r,t,e,n,i,s,a){const o=s.stats.radius;for(let l=0;l<e.cap;l++){const c=e.state[l];if(c!==Zt.Run&&c!==Zt.Fight)continue;const h=e.x[l],u=e.z[l],d=e.str[l],f=.3*Ru(d)+.25;e.state[l]=Zt.Run,e.tx[l]=NaN;const m=i.nearest(h,u,w_);if(m>=0){if(Math.hypot(n.x[m]-h,n.z[m]-u)<=f+Di[n.kind[m]].radius){e.state[l]=Zt.Fight,n.attackers[m]++;const p=n.flash[m]>.05;!n.hit(m,ch(d,t,r),a)&&!p&&a.push(xt.EnemyHit,n.x[m],n.z[m]),n.kind[m]!==3&&e.damage(l,hh(n.dps[m],n.attackersPrev[m],r),a)}else e.tx[l]=n.x[m],e.tz[l]=n.z[m];continue}if(!s.targetable)continue;const v=Math.hypot(s.x-h,s.z-u);if(v<=f+o){if(s.attackers>=Lu)continue;e.state[l]=Zt.Fight,s.attackers++,s.hit(ch(d,t,r),a),e.damage(l,hh(s.stats.meleeDps*s.tier,s.attackersPrev,r),a)}else v<T_&&(e.tx[l]=s.x,e.tz[l]=s.z)}}const Xo=2.5;function A_(r,t,e,n){const i=r.def.op,s=r.def.z+.35;if(i.kind==="div"||i.kind==="sub"){let l;if(i.kind==="div"){const c=t.str[e]+r.carry,h=Math.floor(c/i.value);r.carry=c%i.value,l=t.removeUnits(e,t.str[e]-h,n)}else{if(r.cooldown>0)return 0;r.cooldown=Xo,l=t.removeAny(e,i.value,n)}return r.flash=1,r.lost+=l,l>0&&n.push(xt.GateLoss,r.x,r.def.z,l),-l}let a;if(i.kind==="mul")a=t.str[e]*(i.value-1);else{if(r.cooldown>0)return 0;a=i.value,r.cooldown=Xo}const o=t.add(t.x[e],s,a,Tu,e);return r.flash=1,r.produced+=o,r.activations++,o>0&&n.push(i.kind==="mul"?xt.GateMul:xt.GateAdd,t.x[e],r.def.z,o),o<a&&n.push(xt.GateCapped,r.x,r.def.z,a-o),o}class ua{constructor(t){this.activations=0,this.time=0,this.gates=t.map(e=>({def:e,x:e.x,cooldown:0,flash:0,produced:0,activations:0,lost:0,carry:0})),this.lanes=t.map(e=>({z0:e.z,z1:e.z+.6,x0:e.x-e.width/2,x1:e.x+e.width/2}))}static crossed(t,e,n,i){return n<t.def.z&&i>=t.def.z&&Math.abs(e-t.x)<=t.def.width/2}update(t,e,n,i,s){this.time+=t;for(let a=0;a<this.gates.length;a++){const o=this.gates[a],l=o.def;if(l.moveAmp){o.x=l.x+Math.sin(this.time*(l.moveSpeed??1))*l.moveAmp;const c=this.lanes[a];c.x0=o.x-l.width/2,c.x1=o.x+l.width/2}if(o.cooldown>0&&(o.cooldown=Math.max(0,o.cooldown-t)),o.flash>0&&(o.flash=Math.max(0,o.flash-t*3)),!(l.z<i||l.z>s))for(let c=0;c<e.cap;c++){const h=e.state[c];h!==Zt.Run&&h!==Zt.Fight||ua.crossed(o,e.x[c],e.pz[c],e.z[c])&&A_(o,e,c,n)>0&&this.activations++}}}}const Za=3.4,R_=2;class C_{constructor(t,e=90){this.barrelDamage=e,this.lanes=[],this.time=0,this.unitsKilled=0,this.list=t.map(n=>({def:n,x:0,angle:0,y:1,danger:0,stage:0,t:0}));for(const n of t)n.kind==="bridge"&&this.lanes.push(n)}hitBarrel(t,e,n,i,s,a){for(const o of this.list)if(!(o.def.kind!=="barrel"||o.stage!==0)&&!(Math.hypot(o.def.x-t,o.def.z-e)>n))return this.explode(o,i,s,a),!0;return!1}explode(t,e,n,i){if(t.def.kind!=="barrel"||t.stage!==0)return;t.stage=2;const s=t.def.x,a=t.def.z;i.push(xt.Explosion,s,a,Za);for(let o=0;o<n.cap;o++)n.isAlive(o)&&Math.hypot(n.x[o]-s,n.z[o]-a)<Za&&n.hit(o,this.barrelDamage,i);for(let o=0;o<e.cap;o++)e.isActive(o)&&Math.hypot(e.x[o]-s,e.z[o]-a)<R_&&this.kill(e,o,Zt.Die,i);for(const o of this.list)o.def.kind==="barrel"&&o.stage===0&&Math.hypot(o.def.x-s,o.def.z-a)<Za&&this.explode(o,e,n,i)}kill(t,e,n,i){this.unitsKilled+=t.str[e],t.kill(e,n,i)}update(t,e,n,i,s,a){this.time+=t;for(const o of this.list){const l=o.def;o.t+=t;const c=(h,u)=>u>s-4&&h<a+4;switch(l.kind){case"movingWall":{if(o.x=Math.sin(this.time*l.speed+(l.phase??0))*l.amp,o.danger=2,!c(l.z,l.z))break;const h=l.width/2;for(let u=0;u<e.cap;u++)e.isActive(u)&&(Math.abs(e.x[u]-o.x)>h+.2||e.pz[u]<=l.z+.5&&e.z[u]>=l.z-.5&&this.kill(e,u,Zt.Die,i));break}case"blade":{if(o.angle+=l.speed*t,o.danger=2,!c(l.z-l.radius,l.z+l.radius))break;for(let h=0;h<e.cap;h++){if(!e.isActive(h))continue;const u=e.x[h]-l.x,d=e.z[h]-l.z,f=Math.hypot(u,d);if(f>l.radius+.25)continue;let m=(Math.atan2(d,u)-o.angle)%Math.PI;m>Math.PI/2&&(m-=Math.PI),m<-Math.PI/2&&(m+=Math.PI),(f<.5||Math.abs(m)*f<.45)&&this.kill(e,h,Zt.Die,i)}break}case"crusher":{const h=(this.time+(l.phase??0))%l.period/l.period,u=o.y;if(h<.5?(o.y=1,o.danger=0):h<.74?(o.y=1,o.danger=1):h<.79?(o.y=1-(h-.74)/.05,o.danger=2):h<.9?(o.y=0,o.danger=2):(o.y=(h-.9)/.1,o.danger=0),!c(l.z-l.depth,l.z+l.depth)||(u>0&&o.y===0&&i.push(xt.Impact,l.x,l.z,1),o.danger!==2))break;for(let d=0;d<e.cap;d++)e.isActive(d)&&Math.abs(e.x[d]-l.x)<l.width/2&&Math.abs(e.z[d]-l.z)<l.depth/2&&this.kill(e,d,Zt.Die,i);break}case"laser":{const h=(this.time+(l.phase??0))%l.period/l.period;if(o.danger=h<.4?0:h<.58?1:2,o.danger!==2||!c(l.z,l.z))break;for(let u=0;u<e.cap;u++){if(!e.isActive(u))continue;const d=e.x[u];d<l.x0||d>l.x1||e.pz[u]<=l.z+.3&&e.z[u]>=l.z-.3&&this.kill(e,u,Zt.Die,i)}break}case"bridge":{if(!c(l.z0,l.z1))break;for(let h=0;h<e.cap;h++){if(!e.isActive(h))continue;const u=e.z[h];u<=l.z0||u>=l.z1||(e.x[h]<l.x0||e.x[h]>l.x1)&&this.kill(e,h,Zt.Fall,i)}break}case"fallingPlatform":{if(!c(l.z0,l.z1))break;o.stage===1&&o.t>1.3&&(o.stage=2,i.push(xt.Collapse,(l.x0+l.x1)/2,(l.z0+l.z1)/2)),o.danger=o.stage===0?0:o.stage;for(let h=0;h<e.cap;h++){if(!e.isActive(h))continue;const u=e.z[h],d=e.x[h];u<=l.z0||u>=l.z1||d<l.x0||d>l.x1||(o.stage===0?(o.stage=1,o.t=0):o.stage===2&&this.kill(e,h,Zt.Fall,i))}break}case"barrel":{if(o.stage!==0||!c(l.z,l.z))break;for(let h=0;h<e.cap;h++)if(e.isActive(h)&&Math.abs(e.x[h]-l.x)<.75&&Math.abs(e.z[h]-l.z)<.75){this.explode(o,e,n,i);break}break}}}}}class P_{constructor(){this.cap=48,this.x=new Float32Array(this.cap),this.z=new Float32Array(this.cap),this.startZ=new Float32Array(this.cap),this.live=new Uint8Array(this.cap),this.fired=0,this.deployed=0,this.hits=0}fire(t,e){let n=-1,i=0;for(let s=0;s<this.cap;s++){if(!this.live[s]){n=s;break}this.z[s]-this.startZ[s]>this.z[i]-this.startZ[i]&&(i=s)}n<0&&(n=i),this.live[n]=1,this.x[n]=t,this.z[n]=this.startZ[n]=e,this.fired++}update(t,e,n,i,s,a,o,l,c,h){for(let u=0;u<this.cap;u++){if(!this.live[u])continue;const d=this.x[u],f=this.z[u];let m=f+d_*t,v=!1;const g=a.nearest(d,m,1.7);if(g>=0){const p=Di[s.kind[g]].radius+.35;if(Math.hypot(s.x[g]-d,s.z[g]-m)<p){s.hit(g,e,h),h.push(xt.PodHit,d,m),this.live[u]=0,this.hits++;continue}}if(l.hitBarrel(d,m,.7,i,s,h)||c.podHit(d,m,e,h)){h.push(xt.PodHit,d,m),this.live[u]=0,this.hits++;continue}for(let p=0;p<o.gates.length;p++){const x=o.gates[p];if(ua.crossed(x,d,f,m)){m=x.def.z-.4,v=!0;break}}(m-this.startZ[u]>=f_||m>=n)&&(v=!0),this.z[u]=m,v&&(this.live[u]=0,this.deployed+=i.add(d,Math.min(m,n),1,1),h.push(xt.PodLand,d,m))}}}const Pi=4,Us=Math.ceil((qt*2+2)/Pi);class L_{constructor(t){this.enemies=t,this.head=new Int32Array(0),this.rows=0,this.z0=0,this.next=new Int32Array(t.cap)}build(t,e){this.z0=Math.floor(t/Pi),this.rows=Math.floor(e/Pi)-this.z0+1;const n=this.rows*Us;this.head.length<n&&(this.head=new Int32Array(n)),this.head.fill(-1,0,n);const i=this.enemies;for(let s=0;s<i.cap;s++){if(!i.isAlive(s))continue;const a=Math.floor(i.z[s]/Pi)-this.z0;if(a<0||a>=this.rows)continue;const o=a*Us+this.col(i.x[s]);this.next[s]=this.head[o],this.head[o]=s}}col(t){const e=Math.floor((t+qt+1)/Pi);return e<0?0:e>=Us?Us-1:e}nearest(t,e,n){const i=this.enemies,s=Math.max(0,Math.floor((e-n)/Pi)-this.z0),a=Math.min(this.rows-1,Math.floor((e+n)/Pi)-this.z0),o=this.col(t-n),l=this.col(t+n);let c=-1,h=n*n;for(let u=s;u<=a;u++)for(let d=o;d<=l;d++)for(let f=this.head[u*Us+d];f>=0;f=this.next[f]){const m=i.x[f]-t,v=i.z[f]-e,g=m*m+v*v;g<h&&(h=g,c=f)}return c}}const I_=2e4;class D_{constructor(t,e,n={}){this.level=t,this.stats=e,this.fx=new Wo,this.pods=new P_,this.status="playing",this.time=0,this.peakArmy=0,this.continues=0;const i=new ea(t.seed);this.cannon=new M_(e),this.crowd=new m_(i,n.maxAgents??tr),this.crowd.unitHp=e.unitHealth,this.crowd.unitCap=n.unitCap??er,this.enemies=new S_(i,t.enemyHpScale,t.enemyDmgScale),this.enemies.setWaves(t.waves),this.gates=new ua(t.gates),this.obstacles=new C_(t.obstacles,90*t.enemyHpScale),this.boss=new __(t.boss,t.length,i),this.grid=new L_(this.enemies),this.stopZ=t.length-p_,this.lanes=[...this.obstacles.lanes,...this.gates.lanes],n.startHp!==void 0&&(this.cannon.hp=Math.max(1,Math.min(this.cannon.maxHp,n.startHp)));const s=e.startArmy+Math.max(0,Math.floor(n.extraArmy??0));for(let a=0;a<s;a++)this.crowd.add((a%9-4)*.7,2.5+Math.floor(a/9)*.7,1,1)}get progress(){return Math.min(1,this.cannon.z/this.stopZ)}step(t,e=ts){if(this.status!=="playing")return;const{cannon:n,crowd:i,enemies:s,boss:a,fx:o}=this;this.time+=e;const l=n.update(e,t.aimX,t.ability,this.stopZ,s.blockerZ,o);for(let f=0;f<l;f++)this.pods.fire(n.x,n.z+1.8);const c=n.z-6,h=n.z+Eu+40,u=a.z-a.stats.radius-.5;this.grid.build(c,h),this.pods.update(e,this.stats.podDamage,u,i,s,this.grid,this.gates,this.obstacles,a,o),s.update(e,n.x,n.z,i,this.obstacles.lanes,o),E_(e,this.stats.unitDamage,i,s,this.grid,a,o),i.update(e,n.x,n.z,u,this.lanes),this.gates.update(e,i,o,c,h),this.obstacles.update(e,i,s,o,c,h);const d=a.state!==Jt.Dying&&a.state!==Jt.Dead;a.update(e,n.x,n.z,i,s,o),n.takeDamage(s.cannonDamage+a.cannonDamage,o),i.count>this.peakArmy&&(this.peakArmy=i.count),d&&a.state===Jt.Dying&&(s.killAll(o),i.cheer()),a.state===Jt.Dead?(this.status="won",o.push(xt.Victory,n.x,n.z)):n.hp<=0&&a.state!==Jt.Dying&&(this.status="lost",o.push(xt.Explosion,n.x,n.z,4))}revive(){if(this.status!=="lost")return!1;const{cannon:t,enemies:e,fx:n}=this;this.status="playing",this.continues++,t.hp=t.maxHp*.6,t.shield=3,t.hurt=0;for(let i=0;i<e.cap;i++)e.isAlive(i)&&e.z[i]-t.z<16&&e.hit(i,1/0,n);for(const i of this.boss.telegraphs)i.live=!1;return n.push(xt.Explosion,t.x,t.z,8),n.push(xt.Ability,t.x,t.z),!0}score(){let t=this.enemies.score+this.gates.activations*5;return this.status==="won"&&(t+=1e3+250*this.level.boss.tier,t+=Math.min(1500,this.crowd.count*2),t+=Math.round(this.cannon.hp/this.cannon.maxHp*500),t+=Math.round(Math.max(0,this.level.parTime-this.time)*10)),Math.max(0,Math.min(I_,Math.round(t)))}summary(){const t=this.cannon.hp/this.cannon.maxHp;return{levelId:this.level.id,status:this.status,score:this.score(),time:this.time,enemiesKilled:this.enemies.killed,unitsLost:this.crowd.lost,peakArmy:this.peakArmy,armyLeft:this.crowd.count,gateActivations:this.gates.activations,cannonHp:this.cannon.hp,stars:this.status!=="won"?0:t>=.75?3:t>=.4?2:1}}}const nr=[{id:"classic",name:"Hash Blue",price:0,hue:0,sat:1,light:1,accent:4256511,swatch:["#2b7bff","#40f2ff"]},{id:"emerald",name:"Emerald",price:150,hue:-.25,sat:1,light:1,accent:13172570,swatch:["#19c46a","#c8ff5a"]},{id:"royal",name:"Royal Violet",price:300,hue:.14,sat:1,light:1.05,accent:16747765,swatch:["#8a3dff","#ff8cf5"]},{id:"arctic",name:"Arctic",price:500,hue:0,sat:.14,light:2.3,accent:5232895,swatch:["#eef4ff","#4fd8ff"]},{id:"shadow",name:"Shadow Ops",price:800,hue:0,sat:.3,light:.32,accent:9305930,swatch:["#1c2233","#8dff4a"]},{id:"gold",name:"Solid Gold",price:1200,hue:-.49,sat:1.1,light:1.12,accent:16774064,swatch:["#f5b21a","#fff3b0"]}];function ir(r){return nr.find(t=>t.id===r)??nr[0]}function N_(){return{army:"classic",cannon:"classic",owned:{army:["classic"],cannon:["classic"]}}}function Iu(r,t){if(t.hue===0&&t.sat===1&&t.light===1)return;const e=Math.max(r.r,r.g,r.b),n=Math.min(r.r,r.g,r.b);let i=0,s=0,a=(e+n)/2;const o=e-n;o>1e-6&&(s=a>.5?o/(2-e-n):o/(e+n),e===r.r?i=((r.g-r.b)/o+(r.g<r.b?6:0))/6:e===r.g?i=((r.b-r.r)/o+2)/6:i=((r.r-r.g)/o+4)/6),i=((i+t.hue)%1+1)%1,s=Math.min(1,s*t.sat),a=Math.min(.92,a*t.light);const l=a<.5?a*(1+s):a+s-a*s,c=2*a-l,h=u=>(u=(u%1+1)%1,u<1/6?c+(l-c)*6*u:u<1/2?l:u<2/3?c+(l-c)*(2/3-u)*6:c);r.r=h(i+1/3),r.g=h(i),r.b=h(i-1/3)}const qo=["neon","desert","frozen","cyber","volcanic"],gs={neon:"Neon Highway",desert:"Desert Ruins",frozen:"Frozen Fortress",cyber:"Cyber City",volcanic:"Volcanic Core"};function Du(r){return{add:"+",mul:"×",sub:"−",div:"÷"}[r.kind]+r.value}const U_=.15,F_=11,en=30,uh=["titan","inferno","void"],Ee=r=>({kind:"add",value:r}),re=r=>({kind:"mul",value:r}),Yo=r=>({kind:"sub",value:r}),Nu=r=>({kind:"div",value:r});function Ne(r,t,e){return[{z:r,x:-2.5,width:4.4,op:t},{z:r,x:2.5,width:4.4,op:e}]}function le(r,t,e,n=0){return{z:r,x:n,kind:t,count:t==="grunt"?Math.round(e*1.5):e}}function Uu(r){const t=Math.floor((r-1)/5);return{tier:t,enemyHpScale:1+.12*(r-1),enemyDmgScale:1+.05*(r-1),bossTier:1+t*.5,credits:80+20*r}}function Fu(r){const t=Uu(r),e=new ea(7919*r+13),n=qo[(r-1)%qo.length],i=170+t.tier*12+e.int(0,20),s=[],a=[],o=[];let l=4;const c=2.4+.12*t.tier,h=A=>{l=Math.min(er,l+c*A/Au)},u=(A,C)=>{l=Math.min(er,A.kind==="add"?l+A.value:l*(1+(A.value-1)*C))},d=[Ee(5),Ee(10),Ee(25)],f=t.tier>=2?[re(2),re(3),re(5)]:[re(2),re(3)],m=(A,C)=>{const b=C%2===1;let M=b?e.pick(f):Ee(25),L=b&&e.next()<.45?re(2):e.pick([Ee(5),Ee(10)]);r>=6&&C>0&&e.next()<.3+t.tier*.06&&(L=e.next()<.5?Nu(2):Yo(e.pick([10,25]))),b&&C>1&&e.next()<.1+t.tier*.02&&(M=re(10));const z=e.next()<.5;e.next()<.2+t.tier*.08?(s.push({z:A,x:0,width:3.6,op:M,moveAmp:2.8,moveSpeed:.9+t.tier*.15}),u(M,.55)):(s.push(...Ne(A,z?M:L,z?L:M)),u(M,.8))},v=r>=20?1:-1,g=["barrel","crusher","laser","movingWall","blade","bridge","fallingPlatform"],p=Math.min(g.length,2+t.tier+r%5),x=A=>{const C=g[e.int(0,p-1)],b=e.next()<.5?-1:1;switch(C!=="barrel"&&(l*=.8),C){case"barrel":o.push({kind:C,z:A+6,x:b*e.range(.5,3)});break;case"crusher":o.push({kind:C,z:A,x:b*2.4,width:4.4,depth:3,period:3.2-t.tier*.15,phase:e.range(0,3)});break;case"laser":o.push({kind:C,z:A,x0:b<0?-5:-.5,x1:b<0?.5:5,period:3.4-t.tier*.15,phase:e.range(0,3)});break;case"movingWall":o.push({kind:C,z:A,width:3.4,amp:3.2,speed:.9+t.tier*.12,phase:e.range(0,6)});break;case"blade":o.push({kind:C,z:A,x:b*2.3,radius:2.1,speed:2.2+t.tier*.25});break;case"bridge":o.push({kind:C,z0:A,z1:A+9,x0:b<0?-4.6:-.6,x1:b<0?.6:4.6});break;case"fallingPlatform":o.push({kind:C,z0:A,z1:A+7,x0:b<0?-5:.4,x1:b<0?-.4:5});break}};let y=16,_=0;for(h(y);y<i-62;){const A=y;_===v?(s.push({z:y,x:0,width:2.6,op:re(100),moveAmp:3.6,moveSpeed:1.7}),u(re(100),.35)):m(y,_),y+=e.range(13,16),(_>0||t.tier>0)&&(x(y),y+=13),h(y-A);const C=U_+.01*Math.min(r,20),b=l*C/t.enemyHpScale;let M=Math.round(b*.55),L=_>=1?Math.round(b*.3/4):0,z=_>=2&&l>200?Math.min(3,Math.round(b*.15/28)):0;M=Math.max(6,Math.min(70,M)),L=Math.min(16,L),a.push(le(y,"grunt",M)),L>0&&a.push(le(y+6,"brute",L)),z>0&&a.push(le(y+10,"giant",z,e.range(-2,2))),e.next()<.3+t.tier*.06&&a.push(le(y+3,"turret",1,e.next()<.5?-3.6:3.6)),l*=.75;const R=y+e.range(18,22);h(R-y),y=R,_++}s.push(...Ne(i-42,re(2),e.pick(d))),h(i-42-y),u(re(2),.8);const I=Lu*10*(1+.03*r)*Math.max(1,l/tr),E=Math.round(I*(F_+t.tier)/100)*100;return{id:r,name:`${gs[n]} ${["II","III","IV","V","VI"][t.tier-1]??""}`.trim(),world:n,length:i,gates:s,waves:a,obstacles:o,boss:{kind:uh[(r-1)%uh.length],hp:E,tier:t.bossTier},enemyHpScale:t.enemyHpScale,enemyDmgScale:t.enemyDmgScale,parTime:Math.round(i/3.4+45),reward:{credits:t.credits},seed:1e3+r}}const Ko=5,O_=120,k_=25,B_=2e5;function z_(r){const t=Math.max(1,Math.floor(r));return{...Fu(4+t*2),name:`Stage ${t}`,reward:{credits:30+10*t}}}const H_={bolt:"M13 2 4 14h6l-1 8 9-12h-6z",fire:"M12 2c1 4 5 5 5 10a5 5 0 0 1-10 0c0-2 1-3 2-4 0 2 1 3 2 3 1-2-1-5 1-9z",bot:"M11 2h2v3h-2zM7 10a5 5 0 0 1 10 0v1H7zM6 12h12v7a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2zm3 3v2h2v-2zm4 0v2h2v-2z",sword:"M19 3h2v2L10 16l-2-2zM6 14l4 4-2 2-1-1-2 2-2-2 2-2-1-1z",shield:"M12 2 4 5v6c0 5 3.4 9.3 8 11 4.6-1.7 8-6 8-11V5z",burst:"M12 1l2.6 6.4L21 5l-2.4 6.4L23 14l-6 1 .6 6.5L12 18l-5.6 3.5L7 15l-6-1 4.4-2.6L3 5l6.4 2.4z",gear:"M12 8.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7zm9 5v-3l-2.3-.5a7 7 0 0 0-.8-1.9l1.3-2-2.1-2.1-2 1.3a7 7 0 0 0-1.9-.8L13.5 2h-3L10 4.300a7 7 0 0 0-1.9.8l-2-1.3L4 5.900l1.3 2a7 7 0 0 0-.8 1.9L2 10.500v3l2.300.5c.2.7.4 1.300.8 1.900l-1.300 2L5.900 20l2-1.300c.6.4 1.200.6 1.900.8l.5 2.500h3l.5-2.300a7 7 0 0 0 1.900-.8l2 1.300 2.100-2.100-1.300-2c.4-.6.6-1.200.8-1.900z",trophy:"M7 3h10v2h3v3a4 4 0 0 1-4 4h-.5a5 5 0 0 1-2.500 2.900V18h3v3H8v-3h3v-3.100A5 5 0 0 1 8.500 12H8a4 4 0 0 1-4-4V5h3zM6 7v1a2 2 0 0 0 1 1.700V7zm11 0v2.700A2 2 0 0 0 18 8V7z",grid:"M4 4h7v7H4zm9 0h7v7h-7zM4 13h7v7H4zm9 0h7v7h-7z",up:"M12 3l8 8h-5v10H9V11H4z",lock:"M7 10V7a5 5 0 0 1 10 0v3h1a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1v-9a1 1 0 0 1 1-1zm2 0h6V7a3 3 0 0 0-6 0z",skull:"M12 2a8 8 0 0 0-8 8c0 3 1.500 5 3 6v3h2v-2h2v2h2v-2h2v2h2v-3c1.500-1 3-3 3-6a8 8 0 0 0-8-8zM9 9a2 2 0 1 1 0 4 2 2 0 0 1 0-4zm6 0a2 2 0 1 1 0 4 2 2 0 0 1 0-4z",close:"M6 4.600l6 6 6-6L19.400 6l-6 6 6 6L18 19.400l-6-6-6 6L4.600 18l6-6-6-6z",play:"M7 4l13 8-13 8z",brush:"M20 2 9 13l2 2L22 4zM7.500 14a3.500 3.500 0 0 0-3.500 3.500c0 1.500-1 2.500-2 3 1 .5 2.500.5 4 .5a5 5 0 0 0 5-5l-1.500-1.500A3.500 3.500 0 0 0 7.500 14z",loop:"M7 8a4 4 0 0 0 0 8c1.700 0 3-1 4.200-2.500L12 12.500l.8 1C14 15 15.300 16 17 16a4 4 0 0 0 0-8c-1.700 0-3 1-4.200 2.500l-.8 1-.8-1C10 9 8.700 8 7 8zm0 2c.9 0 1.800.6 2.900 2-1.100 1.400-2 2-2.900 2a2 2 0 0 1 0-4zm10 0a2 2 0 0 1 0 4c-.9 0-1.800-.6-2.900-2 1.100-1.400 2-2 2.900-2z",restart:"M12 5V1L7 6l5 5V7a5 5 0 1 1-5 5H5a7 7 0 1 0 7-7z",exit:"M10 3H4v18h6v-2H6V5h4zm5.600 4.600L14.200 9l2 2H9v2h7.200l-2 2 1.400 1.400L20 12z",next:"M5 4l9 8-9 8zm11 0h3v16h-3z",warn:"M12 2 1 21h22zm-1 7h2v6h-2zm0 8h2v2h-2z",star:"M12 2l3 6.600 7 .8-5.200 4.800 1.500 7L12 17.600 5.700 21.200l1.500-7L2 9.400l7-.8z"};function Ue(r,t=""){const e=document.createElement("span");return e.className=`ic ${t}`.trim(),e.innerHTML=`<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" fill-rule="evenodd" d="${H_[r]}"/></svg>`,e}function D(r,t,...e){const[n,...i]=r.split("."),s=document.createElement(n);i.length&&(s.className=i.join(" ")),t&&Object.assign(s,t);for(const a of e)a&&s.append(a);return s}function Ou(r,...t){r.replaceChildren(...t.filter(e=>!!e))}function ar(r,t,e){return D(`button.btn.${t}`,{type:"button",onclick:e},Ue("close"))}function Cn(r,t,e,n){return D(`button.btn.row.${e}`,{type:"button",onclick:n},Ue(r),D("span",null,t))}function Re(r){return r>=1e6?(r/1e6).toFixed(1)+"M":r>=1e4?(r/1e3).toFixed(1)+"K":String(Math.round(r))}function ku(r){const t=D("div.stars");for(let e=0;e<3;e++)t.append(Ue("star",`star${e<r?" on":""}`));return t}class V_{constructor(t,e){this.onPick=t,this.grid=D("div.skin-grid"),this.balance=D("span.credit-num"),this.wallet=D("div.credits",null,D("span.credit-icon"),this.balance),this.tabs=D("div.segmented"),this.kind="army",this.save=null,this.shop=null,this.el=D("div.screen.sheet-screen",null,D("div.panel.sheet",null,D("div.panel-head",null,D("h2.title",null,"Skins"),this.wallet,ar("✕","close",e)),this.tabs,this.grid))}refresh(t,e){this.save=t,this.shop=e;const n=e?.balance??null;this.wallet.hidden=n==null,this.balance.textContent=n==null?"":Re(n),this.tabs.replaceChildren();for(const s of["army","cannon"]){const a=D(`button${this.kind===s?".on":""}`,{type:"button"},s==="army"?"ARMY":"CANNON");a.onclick=()=>{this.kind=s,this.save&&this.refresh(this.save,this.shop)},this.tabs.append(a)}const i=this.kind;this.grid.replaceChildren(),this.grid.classList.remove("busy");for(const s of nr){const a=t.skins.owned[i].includes(s.id),o=t.skins[i]===s.id,l=D("div.skin-swatch");l.style.background=`linear-gradient(145deg, ${s.swatch[0]} 0 62%, ${s.swatch[1]} 62%)`;const c=o?D("span.skin-state.on",null,"EQUIPPED"):a?D("span.skin-state",null,"EQUIP"):this.priceTag(e?.skins[s.id]??null,n),h=D(`button.skin${o?".equipped":""}`,{type:"button"},l,D("span.skin-name",null,s.name),c);h.onclick=()=>{a||(c.classList.add("loading"),this.grid.classList.add("busy")),this.onPick(i,s.id)},this.grid.append(h)}}priceTag(t,e){if(t==null)return D("span.skin-state.price.poor",null,Ue("lock"));const n=e!=null&&e<t;return D(`span.skin-state.price${n?".poor":""}`,null,n?Ue("lock"):D("span.credit-icon"),Re(t))}}const Ja=9;class G_{constructor(t){this.actions=t,this.cost=D("b"),this.currency=D("span"),this.ring=D("div.count-ring"),this.num=D("div.count-num"),this.note=D("div.note"),this.timer=0,this.left=Ja,this.payBtn=D("button.btn.primary.pay",{type:"button",onclick:()=>this.actions.pay()},D("span",null,"CONTINUE"),D("span.pay-cost",null,D("span.credit-icon"),this.cost,this.currency)),this.el=D("div.screen.panel-screen.dim",null,D("div.panel.narrow.continue",null,D("h2.title",null,"Continue?"),D("div.count",null,this.ring,this.num),D("div.result-sub",null,"Revive your cannon right here. Your army, progress and score are kept."),this.payBtn,Cn("close","NO THANKS","ghost",()=>this.actions.decline()),this.note))}show(t){this.cost.textContent=Re(t.cost),this.currency.textContent=` ${t.currency}`,this.note.textContent="",this.payBtn.disabled=!1,this.payBtn.classList.remove("loading"),this.left=Ja,this.tick(),window.clearInterval(this.timer),this.timer=window.setInterval(()=>{this.left--,this.tick(),this.left<=0&&(this.stop(),this.actions.decline())},1e3)}tick(){this.num.textContent=String(Math.max(0,this.left)),this.ring.style.setProperty("--left",String(this.left/Ja*360))}busy(){this.stop(),this.payBtn.disabled=!0,this.payBtn.classList.add("loading"),this.note.textContent="Processing…"}failed(){this.payBtn.disabled=!1,this.payBtn.classList.remove("loading"),this.note.textContent="Not charged. You can try again or skip."}stop(){window.clearInterval(this.timer)}}const _i={fireRate:{id:"fireRate",name:"Fire Rate",desc:"Pods launched per second",maxLevel:15,baseCost:60,costGrowth:1.32,value:r=>2.4+.3*r,format:r=>`${r.toFixed(1)}/s`},startArmy:{id:"startArmy",name:"Starting Army",desc:"Units deployed at level start",maxLevel:15,baseCost:50,costGrowth:1.3,value:r=>3*r,format:r=>`${r}`},unitDamage:{id:"unitDamage",name:"Unit Damage",desc:"Damage per second per unit",maxLevel:15,baseCost:70,costGrowth:1.34,value:r=>10+1.5*r,format:r=>r.toFixed(1)},unitHealth:{id:"unitHealth",name:"Unit Armor",desc:"Hit points per unit",maxLevel:15,baseCost:70,costGrowth:1.34,value:r=>10+1.5*r,format:r=>r.toFixed(1)},cannonPower:{id:"cannonPower",name:"Cannon Power",desc:"Direct-hit pod damage",maxLevel:15,baseCost:60,costGrowth:1.32,value:r=>14+6*r,format:r=>`${r}`},abilityCooldown:{id:"abilityCooldown",name:"Overdrive",desc:"Cooldown of the rapid-fire burst",maxLevel:10,baseCost:90,costGrowth:1.4,value:r=>24-1.4*r,format:r=>`${r.toFixed(1)}s`}},Bu=Object.keys(_i);function W_(){return{fireRate:0,startArmy:0,unitDamage:0,unitHealth:0,cannonPower:0,abilityCooldown:0}}function Oy(r,t){const e=_i[r];return Math.round(e.baseCost*Math.pow(e.costGrowth,t)/5)*5}function X_(r){const t=e=>_i[e].value(Math.min(Math.max(0,r[e]|0),_i[e].maxLevel));return{fireRate:t("fireRate"),startArmy:t("startArmy"),unitDamage:t("unitDamage"),unitHealth:t("unitHealth"),podDamage:t("cannonPower"),abilityCooldown:t("abilityCooldown")}}const q_="modulepreload",Y_=function(r,t){return new URL(r,t).href},dh={},K_=function(t,e,n){let i=Promise.resolve();if(e&&e.length>0){const a=document.getElementsByTagName("link"),o=document.querySelector("meta[property=csp-nonce]"),l=o?.nonce||o?.getAttribute("nonce");i=Promise.allSettled(e.map(c=>{if(c=Y_(c,n),c in dh)return;dh[c]=!0;const h=c.endsWith(".css"),u=h?'[rel="stylesheet"]':"";if(!!n)for(let m=a.length-1;m>=0;m--){const v=a[m];if(v.href===c&&(!h||v.rel==="stylesheet"))return}else if(document.querySelector(`link[href="${c}"]${u}`))return;const f=document.createElement("link");if(f.rel=h?"stylesheet":q_,h||(f.as="script"),f.crossOrigin="",f.href=c,l&&f.setAttribute("nonce",l),document.head.appendChild(f),h)return new Promise((m,v)=>{f.addEventListener("load",m),f.addEventListener("error",()=>v(new Error(`Unable to preload CSS for ${c}`)))})}))}function s(a){const o=new Event("vite:preloadError",{cancelable:!0});if(o.payload=a,window.dispatchEvent(o),!o.defaultPrevented)throw a}return i.then(a=>{for(const o of a||[])o.status==="rejected"&&s(o.reason);return t().catch(s)})};function $_(){const r=window.flutter_inappwebview;return r&&typeof r.callHandler=="function"?r:null}class j_{constructor(t){this.bridge=t,this.name="hash-app"}async getPlayer(){return{userId:null,displayName:"You",isGuest:!1}}async startSession(){return{sessionId:`${Date.now().toString(36)}-${Math.random().toString(36).slice(2,8)}`}}async submitScore(t){const e=await this.bridge.callHandler("gameScore",{score:t.score,runId:t.runId,level:t.level,levelScore:t.levelScore,stars:t.stars,durationMs:t.durationMs,...t.proof});return{accepted:e?.accepted===!0,message:e?.message}}async getLeaderboard(){return null}async getRewardEligibility(){return{eligible:!0,description:"Rewards are decided by Hash Arcade."}}track(t,e={}){this.bridge.callHandler("analytics",{event:`hash_rush_${t}`,params:e}).catch(()=>{})}haptic(t){this.bridge.callHandler("haptic",t).catch(()=>{})}async continueOffer(){const t=await this.bridge.callHandler("coinContinue",{quote:!0});return typeof t?.cost=="number"&&t.cost>0?{cost:t.cost,currency:"HashCoins"}:null}async payContinue(){return(await this.bridge.callHandler("coinContinue",{quote:!1}))?.ok===!0}async shopCatalog(){const t=await this.bridge.callHandler("coinShop",{action:"catalog"});return!t||typeof t.upgrades!="object"||typeof t.skins!="object"?null:{currency:"HashCoins",balance:typeof t.balance=="number"?t.balance:null,upgrades:t.upgrades,skins:t.skins,owned:Z_(t.owned)}}async buyItem(t){const e=await this.bridge.callHandler("coinShop",{action:"buy",...t});return{ok:e?.ok===!0,balance:typeof e?.balance=="number"?e.balance:null}}}function Z_(r){const t=n=>Array.isArray(n)?n.filter(i=>typeof i=="string"):[],e=r??{};return{army:t(e.army),cannon:t(e.cannon)}}async function J_(){const r=$_();if(r)return new j_(r);const{MockAdapter:t}=await K_(async()=>{const{MockAdapter:e}=await import("./MockAdapter.js");return{MockAdapter:e}},[],import.meta.url);return new t}const Fs=(r,t)=>{const e=Uu(r);return{id:r,enemyHpScale:e.enemyHpScale,enemyDmgScale:e.enemyDmgScale,parTime:t,reward:{credits:e.credits},seed:1e3+r}},Q_=[{...Fs(1,75),name:"First Contact",world:"neon",length:132,gates:[...Ne(16,Ee(10),Ee(5)),...Ne(36,Ee(5),re(2)),...Ne(72,re(3),re(2))],waves:[le(52,"grunt",10),le(88,"grunt",18),le(93,"brute",2)],obstacles:[{kind:"barrel",z:87,x:0}],boss:{kind:"titan",hp:4600,tier:1}},{...Fs(2,90),name:"Buried Legion",world:"desert",length:156,gates:[...Ne(16,Ee(25),Ee(10)),{z:40,x:0,width:3.8,op:re(2),moveAmp:2.6,moveSpeed:.9},...Ne(88,Ee(10),re(3)),...Ne(114,re(2),Ee(25))],waves:[le(54,"grunt",14),le(58,"brute",3),le(100,"grunt",22),le(105,"brute",5)],obstacles:[{kind:"bridge",z0:66,z1:76,x0:-1,x1:4.6},{kind:"crusher",z:82,x:-2.4,width:4.4,depth:3,period:3.2},{kind:"barrel",z:103,x:-2}],boss:{kind:"inferno",hp:5400,tier:1}},{...Fs(3,95),name:"Cold Front",world:"frozen",length:164,gates:[...Ne(16,Ee(25),re(2)),...Ne(46,re(3),Ee(10)),{z:96,x:0,width:3.8,op:re(3),moveAmp:2.8,moveSpeed:1.1},...Ne(122,Yo(10),re(2))],waves:[le(60,"grunt",18),le(63,"turret",1,3.6),le(108,"grunt",24),le(112,"brute",6),le(110,"turret",1,-3.6)],obstacles:[{kind:"laser",z:32,x0:-5,x1:.4,period:3.4},{kind:"fallingPlatform",z0:72,z1:80,x0:.4,x1:5},{kind:"laser",z:88,x0:-.4,x1:5,period:3.2,phase:1.5}],boss:{kind:"void",hp:6e3,tier:1}},{...Fs(4,100),name:"Overclocked",world:"cyber",length:176,gates:[...Ne(16,re(2),Ee(25)),...Ne(50,Ee(10),re(5)),...Ne(100,Nu(2),re(3)),{z:132,x:0,width:3.6,op:re(3),moveAmp:3,moveSpeed:1.2}],waves:[le(64,"grunt",26),le(69,"brute",5),le(114,"grunt",30),le(119,"brute",6),le(124,"giant",1)],obstacles:[{kind:"movingWall",z:34,width:3,amp:3.2,speed:1},{kind:"blade",z:82,x:-2.3,radius:2.1,speed:2.4},{kind:"blade",z:90,x:2.3,radius:2.1,speed:-2.4},{kind:"barrel",z:117,x:1.5}],boss:{kind:"titan",hp:5e3,tier:1.5}},{...Fs(5,110),name:"Meltdown",world:"volcanic",length:190,gates:[...Ne(16,Ee(25),re(2)),{z:44,x:0,width:3.4,op:re(10),moveAmp:3.2,moveSpeed:1.3},...Ne(98,re(3),Ee(25)),...Ne(146,re(3),Yo(25))],waves:[le(58,"grunt",30),le(63,"brute",6),le(61,"turret",1,-3.6),le(112,"grunt",30),le(117,"brute",6),le(122,"giant",1),le(114,"turret",1,3.6)],obstacles:[{kind:"crusher",z:30,x:2.4,width:4.4,depth:3,period:3},{kind:"bridge",z0:72,z1:82,x0:-4.6,x1:1},{kind:"laser",z:90,x0:-5,x1:.4,period:3},{kind:"barrel",z:115,x:-1},{kind:"barrel",z:118,x:2},{kind:"fallingPlatform",z0:130,z1:138,x0:-5,x1:-.4},{kind:"movingWall",z:156,width:3.2,amp:3.2,speed:1.2}],boss:{kind:"inferno",hp:6e3,tier:1.5}}],fh=new Map;function Ys(r){const t=Math.min(en,Math.max(1,Math.floor(r)));let e=fh.get(t);return e||(e=Q_[t-1]??Fu(t),fh.set(t,e)),e}const tx={low:{level:"low",maxPixelRatio:1,lowPolyCrowd:!0,particles:350,propDensity:.4,ambientParticles:0,blobShadows:!1,antialias:!1,bloom:!1},medium:{level:"medium",maxPixelRatio:1.5,lowPolyCrowd:!0,particles:800,propDensity:.7,ambientParticles:140,blobShadows:!0,antialias:!1,bloom:!0},high:{level:"high",maxPixelRatio:2,lowPolyCrowd:!1,particles:1500,propDensity:1,ambientParticles:320,blobShadows:!0,antialias:!0,bloom:!0}},ph=["low","medium","high"];function mh(){const r=typeof navigator>"u"?void 0:navigator;if(!r)return"medium";const t=/Android|iPhone|iPad|iPod/i.test(r.userAgent),e=r.hardwareConcurrency??4,n=r.deviceMemory??4;return t?e>=8&&n>=6?"medium":e<=4||n<=3?"low":"medium":e>=8?"high":"medium"}const yn=class yn{constructor(t,e){this.onChange=e,this.scale=1,this.sum=0,this.frames=0,this.slowWindows=0,this.auto=t==="auto",this.level=t==="auto"?mh():t}get preset(){return tx[this.level]}pixelRatio(t){return Math.max(.5,Math.min(t,this.preset.maxPixelRatio)*this.scale)}set(t){this.auto=t==="auto";const e=t==="auto"?mh():t,n=e!==this.level;this.level=e,this.scale=1,this.slowWindows=0,this.onChange(this.preset,n)}sample(t){if(t>120||(this.sum+=t,++this.frames<yn.WINDOW))return;const e=this.sum/this.frames;this.sum=0,this.frames=0,e>yn.SLOW_MS?(this.slowWindows++,this.scale>yn.MIN_SCALE+.01?(this.scale=Math.max(yn.MIN_SCALE,this.scale-.15),this.onChange(this.preset,!1)):this.auto&&this.slowWindows>=3&&this.level!=="low"&&(this.level=ph[ph.indexOf(this.level)-1],this.scale=1,this.slowWindows=0,this.onChange(this.preset,!0))):(this.slowWindows=0,e<yn.FAST_MS&&this.scale<1&&(this.scale=Math.min(1,this.scale+.1),this.onChange(this.preset,!1)))}};yn.WINDOW=90,yn.SLOW_MS=21,yn.FAST_MS=13.5,yn.MIN_SCALE=.6;let $o=yn;const li=r=>r*r*(3-2*r),Ve=r=>r<0?0:r>1?1:r;class ex{constructor(t,e){this.boss=t,this.group=new De,this.parts={},this.mats=[],this.height=7,this.model=e.model(`boss_${t.kind}`),this.model.traverse(n=>{n.name&&(this.parts[n.name]=this.parts[n.name]??n);const i=n;if(!i.isMesh)return;const s=i.material;if(this.mats.some(o=>o.mat===s))return;const a=s.emissive.r+s.emissive.g+s.emissive.b>.01;a&&(s.emissiveIntensity=1.6),this.mats.push({mat:s,base:s.emissive.clone(),glows:a,intensity:s.emissiveIntensity})}),this.group.add(this.model),this.shield=new Rt(new ys(t.stats.radius+2.4,20,14),new ne({color:11561983,transparent:!0,opacity:.25,blending:dn,depthWrite:!1,wireframe:!1})),this.shield.position.y=4,this.shield.visible=!1,this.group.add(this.shield),this.group.visible=!1}update(t){const e=this.boss,{torso:n,head:i,armL:s,armR:a,legL:o,legR:l,ring:c,core:h}=this.parts,u=this.group;if(u.visible=e.state!==Jt.Dormant&&e.state!==Jt.Dead,!u.visible)return;let f=e.kind==="void"?1.1+Math.sin(t*1.6)*.3:0,m=1,v=0,g=Math.sin(t*1.3)*.08,p=-Math.sin(t*1.3)*.08,x=0,y=Math.sin(t*.9)*.05,_=Math.sin(t*1.3)*.025,I=0;if(e.state===Jt.Intro){const C=Ve(e.t/Cu);if(e.kind==="titan"){const b=Ve(e.t/.8);f=(1-b*b)*34;const M=Ve((e.t-.8)/.4);m=1-Math.sin(M*Math.PI)*.1,x=li(Ve((e.t-1.3)/.6))*.9*(1-Ve((e.t-2.2)/.4)),y=-x*.4}else if(e.kind==="inferno"){f=-9*(1-li(Ve(e.t/1.3)));const b=Math.sin(Ve((e.t-1.4)/1)*Math.PI);y=-b*.6,g=p=-b*.8}else f+=(1-li(C))*16,m=.3+.7*li(Ve(e.t/1.6)),x=(1-li(C))*1.2}else if(e.state===Jt.Fight){const C=e.attackT;if(C<1.7&&e.attack){const b=li(Ve(C/1)),M=Ve((C-1.1)/.18),L=Ve((C-1.3)/.4),z=-2.5*b*(1-M)+.5*M*(1-L);switch(e.attack){case"slam":case"stomp":g=p=z,_=-.18*b+.34*M*(1-L),e.attack==="stomp"&&(I=-.7*b*(1-M));break;case"boulder":case"fireball":case"orbs":p=z,_=-.1*b+.2*M*(1-L);break;case"flame":case"beam":y=.45*b*(1-L),g=p=.5*b*(1-L),_=.2*b*(1-L);break;case"summon":case"blink":x=Math.sin(Ve(C/1.4)*Math.PI)*1.1,y=-.3*Math.sin(Ve(C/1.4)*Math.PI);break}}e.enraged&&(u.position.x+=Math.sin(t*50)*.03)}else if(e.state===Jt.Dying){const C=Ve(e.t/Pu);v=-li(C)*1.25,f+=-C*C*3+Math.sin(t*70)*.08*(1-C),m=1-li(Ve((C-.7)/.3))*.6,x=C*1.2,y=-C*.6}u.position.set(e.x+(e.state===Jt.Dying?Math.sin(t*61)*.12:0),f,-e.z),u.scale.setScalar(m),this.model.rotation.x=v,n&&(n.rotation.x=_),i&&(i.rotation.x=y),s&&s.rotation.set(g,0,-x),a&&a.rotation.set(p,0,x),o&&(o.rotation.x=I),l&&(l.rotation.x=0),c&&(c.rotation.y=t*1.4),h&&h.scale.setScalar(1+Math.sin(t*6)*.15);const E=e.flash,A=e.enraged?.6+Math.sin(t*12)*.4:0;for(const C of this.mats)C.glows?C.mat.emissiveIntensity=C.intensity*(1+A)+E*2:C.mat.emissive.setRGB(E*.3,E*.26,E*.22);if(this.shield.visible=e.shield>0,this.shield.visible){const C=this.shield.material;C.opacity=.14+.2*(e.shield/Math.max(1,e.shieldMax))+Math.sin(t*9)*.04,this.shield.rotation.y=t}}dispose(){for(const t of this.mats)t.mat.dispose();this.shield.geometry.dispose(),this.shield.material.dispose(),this.group.removeFromParent()}}const xn={Idle:0,Run:1,Attack:2,Fall:3,Die:4,Cheer:5,Static:6},zu={value:0},nx=`
attribute float aPart;
attribute float aEmit;
attribute vec4 iAnim; // phase, clip, flash, speed
uniform vec3 uPivot[6];
uniform float uTime;
varying float vEmit;
varying float vFlash;
vec3 hrRot(vec3 p, float a) {
  float c = cos(a), s = sin(a);
  return vec3(p.x, p.y * c - p.z * s, p.y * s + p.z * c);
}
// Limb swing angle (about the part's joint, X axis) and whole-body lift for this vertex.
float hrAngle(out float lift) {
  float clip = iAnim.y;
  float ph = iAnim.x + uTime * iAnim.w;
  bool arm = aPart > 0.5 && aPart < 2.5;
  bool leg = aPart > 2.5 && aPart < 4.5;
  float side = (abs(aPart - 1.0) < 0.5 || abs(aPart - 4.0) < 0.5) ? 1.0 : -1.0;
  lift = 0.0;
  if (clip < 0.5) { // idle: breathe
    lift = sin(ph) * 0.012;
    return arm ? sin(ph) * 0.07 * side : 0.0;
  }
  if (clip < 1.5) { // run
    lift = abs(sin(ph)) * 0.07;
    if (arm) return sin(ph) * 0.85 * side;
    if (leg) return -sin(ph) * 0.95 * side;
    return 0.0;
  }
  if (clip < 2.5) { // attack: alternate punches
    lift = abs(sin(ph * 0.5)) * 0.04;
    if (arm) return -1.45 + sin(ph + (side > 0.0 ? 0.0 : 3.1416)) * 0.85;
    if (leg) return side * 0.3;
    return 0.0;
  }
  if (clip < 4.5) { // fall / die: flail
    return (arm || leg) ? sin(ph * 1.7 + aPart * 2.0) * 1.4 : 0.0;
  }
  if (clip < 5.5) { // cheer: arms up, hop
    lift = abs(sin(ph * 0.5)) * 0.32;
    return arm ? -2.75 + sin(ph) * 0.3 * side : 0.0;
  }
  return 0.0;
}
`;function ix(r){const t=new Ke({vertexColors:!0});return t.onBeforeCompile=e=>{e.uniforms.uPivot={value:r},e.uniforms.uTime=zu,e.vertexShader=e.vertexShader.replace("#include <common>",`#include <common>
`+nx).replace("#include <beginnormal_vertex>",`#include <beginnormal_vertex>
float hrLift;
float hrA = hrAngle(hrLift);
objectNormal = hrRot(objectNormal, hrA);`).replace("#include <begin_vertex>",`#include <begin_vertex>
        vec3 hrP = uPivot[int(aPart + 0.5)];
        transformed = hrRot(transformed - hrP, hrA) + hrP;
        transformed.y += hrLift;
        vEmit = aEmit;
        vFlash = iAnim.z;`),e.fragmentShader=e.fragmentShader.replace("#include <common>",`#include <common>
varying float vEmit;
varying float vFlash;`).replace("#include <emissivemap_fragment>",`#include <emissivemap_fragment>
        float hrRim = pow(1.0 - clamp(dot(normalize(vViewPosition), normal), 0.0, 1.0), 2.5);
        totalEmissiveRadiance += diffuseColor.rgb * (vEmit * 2.6 + hrRim * 0.75) + vec3(vFlash * 0.55);
        diffuseColor.rgb = mix(diffuseColor.rgb, vec3(1.0), vFlash * 0.7);`)},t.customProgramCacheKey=()=>"hash-rush-bot",t}class Or{constructor(t,e,n){this.capacity=e,this.n=0;const i=t.geometry.clone();if(n){const s=i.attributes.color,a=i.attributes.aEmit,o=new dt(n.accent),l={r:0,g:0,b:0};for(let c=0;c<s.count;c++)a.getX(c)>.5?s.setXYZ(c,o.r,o.g,o.b):(l.r=s.getX(c),l.g=s.getY(c),l.b=s.getZ(c),Iu(l,n),s.setXYZ(c,l.r,l.g,l.b))}this.anim=new Float32Array(e*4),this.animAttr=new Qs(this.anim,4),this.animAttr.setUsage(Yn),i.setAttribute("iAnim",this.animAttr),this.mesh=new Ni(i,ix(t.pivots),e),this.mesh.instanceMatrix.setUsage(Yn),this.mesh.frustumCulled=!1,this.matrices=this.mesh.instanceMatrix.array,this.colors=new Float32Array(e*3).fill(1),this.mesh.instanceColor=new Qs(this.colors,3),this.mesh.instanceColor.setUsage(Yn),this.mesh.count=0}begin(){this.n=0}push(t,e,n,i,s,a,o,l,c,h,u,d=1,f=1,m=1){if(this.n>=this.capacity)return;const v=this.n++,g=this.matrices,p=v*16,x=o===0?1:Math.cos(o),y=o===0?0:Math.sin(o);g[p]=i*a,g[p+1]=0,g[p+2]=-s*a,g[p+3]=0,g[p+4]=s*y*a,g[p+5]=x*a,g[p+6]=i*y*a,g[p+7]=0,g[p+8]=s*x*a,g[p+9]=-y*a,g[p+10]=i*x*a,g[p+11]=0,g[p+12]=t,g[p+13]=e,g[p+14]=n,g[p+15]=1;const _=v*4;this.anim[_]=l,this.anim[_+1]=c,this.anim[_+2]=h,this.anim[_+3]=u;const I=v*3;this.colors[I]=d,this.colors[I+1]=f,this.colors[I+2]=m}end(){this.mesh.count=this.n,this.mesh.instanceMatrix.needsUpdate=!0,this.animAttr.needsUpdate=!0,this.mesh.instanceColor.needsUpdate=!0}get count(){return this.n}dispose(){this.mesh.geometry.dispose(),this.mesh.material.dispose()}}class sx{constructor(){this.camera=new ze(58,9/16,.5,420),this.pos=new P(0,12,12),this.look=new P(0,0,-10),this.wantPos=new P,this.wantLook=new P,this.shakeAmount=0,this.snap=!0,this.lookDrop=0}setAspect(t){this.camera.aspect=t;const n=2*Math.atan(Math.tan(36*Math.PI/360)/t)*180/Math.PI;this.camera.fov=Math.max(40,Math.min(66,n)),this.camera.updateProjectionMatrix()}shake(t){this.shakeAmount=Math.min(1.2,Math.max(this.shakeAmount,t))}reset(){this.snap=!0,this.shakeAmount=0}update(t,e,n,i){const s=e.cannon,a=e.boss,o=Math.min(1,Math.sqrt(e.crowd.count)/22),l=e.enemies.blockerZ<1/0?1:0;let c=8.6+o*3.6+l*1,h=9.4+o*2.4+l*.8,u=7.5+o*3.5,d=s.x*.32,f=s.x*.2;if(a.state===Jt.Intro){const v=Math.min(1,a.t/.6);c=9.5,h=9,u=jh.lerp(u,a.z-s.z,v),this.wantLook.set(f*.3,4.5*v,-(s.z+u))}else a.state===Jt.Fight||a.state===Jt.Dying?(c=13.5,h=9.5,u=(a.z-s.z)*.62,this.wantLook.set(f*.4,1.5,-(s.z+u))):this.wantLook.set(f,.5,-(s.z+u));if(i){const v=Math.sin(n*.22)*.7;this.wantPos.set(Math.sin(v)*7,2.7+Math.sin(n*.4)*.3,-(s.z+3)-Math.cos(v)*7.5),this.wantLook.set(0,2.3-this.lookDrop,-(s.z+1.8))}else this.wantPos.set(d,c,-s.z+h);const m=this.snap?1:1-Math.exp(-t*4.5);if(this.snap=!1,this.pos.lerp(this.wantPos,m),this.look.lerp(this.wantLook,m),this.camera.position.copy(this.pos),this.shakeAmount>.002){const v=this.shakeAmount*.45;this.camera.position.x+=(Math.random()-.5)*v,this.camera.position.y+=(Math.random()-.5)*v,this.shakeAmount*=Math.exp(-t*7)}this.camera.position.y<3&&(this.camera.position.y=3),this.camera.lookAt(this.look)}}class rx{constructor(t,e,n){this.cannon=t,this.group=new De,this.barrelRest=new P,this.mats=[],this.glowMats=[],this.lastX=0,this.bank=0,this.model=e.model("cannon"),this.model.rotation.y=Math.PI,this.model.traverse(s=>{const a=s;if(!a.isMesh)return;const o=a.material;this.mats.includes(o)||this.glowMats.includes(o)||(o.emissive.r+o.emissive.g+o.emissive.b>.01?(o.emissiveIntensity=1.8,o.emissive.b>o.emissive.r&&(o.emissive.setHex(n.accent),o.color.setHex(n.accent)),this.glowMats.push(o)):(Iu(o.color,n),this.mats.push(o)))}),this.barrel=this.model.getObjectByName("barrel"),this.barrel&&this.barrelRest.copy(this.barrel.position);const i=(()=>{const s=document.createElement("canvas");s.width=s.height=64;const a=s.getContext("2d"),o=a.createRadialGradient(32,32,0,32,32,32);return o.addColorStop(0,"rgba(255,255,255,1)"),o.addColorStop(.3,"rgba(140,235,255,0.8)"),o.addColorStop(1,"rgba(60,160,255,0)"),a.fillStyle=o,a.fillRect(0,0,64,64),new sr(s)})();this.flashMesh=new Rt(new We(2.2,2.2),new ne({map:i,transparent:!0,blending:dn,depthWrite:!1,opacity:0})),this.flashMesh.position.set(0,.95,-1.9),this.glowRing=new Rt(new Fi(1,1.25,32).rotateX(-Math.PI/2),new ne({color:5235711,transparent:!0,opacity:.5,blending:dn,depthWrite:!1})),this.glowRing.position.y=-.2,this.group.add(this.model,this.flashMesh,this.glowRing)}update(t,e,n){const i=this.cannon,s=e>0?(i.x-this.lastX)/e:0;this.lastX=i.x,this.bank+=(Math.max(-.35,Math.min(.35,-s*.035))-this.bank)*Math.min(1,e*10),this.group.position.set(i.x,.3+Math.sin(t*3)*.06,-i.z),this.model.rotation.z=-this.bank,this.barrel&&this.barrel.position.copy(this.barrelRest).setZ(this.barrelRest.z-i.recoil*.3);const a=this.flashMesh.material;a.opacity=i.recoil*i.recoil,this.flashMesh.scale.setScalar(.6+i.recoil*.8),this.flashMesh.quaternion.copy(n.quaternion);const o=i.overdrive>0,l=this.glowRing.material;l.color.setHex(o?16765498:5235711),l.opacity=(o?.8:.4)+Math.sin(t*(o?18:4))*.15,this.glowRing.scale.setScalar(o?1.25:1);for(const c of this.mats)c.emissive.setRGB(i.hurt*.9,i.hurt*.1,i.hurt*.05)}dispose(){this.group.traverse(t=>{const e=t;e.isMesh&&e.material.dispose()}),this.group.removeFromParent()}}const ax=7,ox=90;class lx{constructor(t,e,n){this.group=new De,this.dummy=new he,this.drawn=0;const i=e.lowPolyCrowd?"_lo":"";if(this.blue=new Or(t.bot(`blue_bot${i}`),tr,n),this.grunt=new Or(t.bot(`red_grunt${i}`),Be),this.brute=new Or(t.bot(`red_brute${i}`),96),this.turret=new Or(t.bot("turret"),16),this.group.add(this.blue.mesh,this.grunt.mesh,this.brute.mesh,this.turret.mesh),e.blobShadows){const a=new la(.42,10).rotateX(-Math.PI/2),o=new ne({color:0,transparent:!0,opacity:.3,depthWrite:!1});this.shadows=new Ni(a,o,tr+Be),this.shadows.instanceMatrix.setUsage(Yn),this.shadows.frustumCulled=!1,this.shadows.renderOrder=1,this.group.add(this.shadows)}else this.shadows=null;const s=new bl(.16,.42,3,8).rotateX(Math.PI/2);this.pods=new Ni(s,new ne({color:9431551}),48),this.bolts=new Ni(new ys(.2,8,6),new ne({color:16734780}),24);for(const a of[this.pods,this.bolts])a.instanceMatrix.setUsage(Yn),a.frustumCulled=!1,a.count=0,this.group.add(a)}shadowAt(t,e,n,i){const s=this.shadows.instanceMatrix.array,a=t*16;s.fill(0,a,a+16),s[a]=i,s[a+5]=1,s[a+10]=i,s[a+15]=1,s[a+12]=e,s[a+13]=.02,s[a+14]=-n}update(t){const{crowd:e,enemies:n}=t,i=t.cannon.z-ax,s=t.cannon.z+ox;let a=0;this.blue.begin();for(let c=0;c<e.cap;c++){const h=e.state[c];if(h===Zt.Dead)continue;const u=e.z[c];if(u<i||u>s)continue;const d=e.x[c],f=e.t[c],m=e.str[c];let v=Ru(m)*1.3,g=0,p=0,x=xn.Run,y=15;h===Zt.Run?(e.speed[c]<.6&&(x=xn.Idle,y=4),f<.18&&(v*=.4+f/.18*.6)):h===Zt.Fight?(x=xn.Attack,y=17):h===Zt.Cheer?(x=xn.Cheer,y=11):h===Zt.Fall?(x=xn.Fall,g=-f*f*16,p=f*5):(x=xn.Die,g=Math.sin(Math.min(1,f/.6)*Math.PI)*.7,p=f*4,v*=Math.max(0,1-f/.65));const _=m>1?1.25:1;this.blue.push(d,g,-u,-1,0,v,p,e.phase[c],x,0,y,_,_,_),this.shadows&&g===0&&this.shadowAt(a++,d,u,v*.85)}this.blue.end(),this.grunt.begin(),this.brute.begin(),this.turret.begin();for(let c=0;c<n.cap;c++){const h=n.state[c];if(h===_e.Dead)continue;const u=n.z[c];if(u<i||u>s)continue;const d=n.kind[c],f=Di[d],m=n.x[c],v=n.t[c];let g=f.scale*(d===3?1:1.25),p=0,x=u,y=0,_=h===_e.March?xn.Run:h===_e.Fight?xn.Attack:xn.Idle,I=h===_e.March?9/Math.sqrt(g):h===_e.Fight?12/Math.sqrt(g):3;if(h===_e.Dying){_=xn.Die,I=14;const A=v/.6;x=u+A*1.6,p=Math.sin(A*Math.PI)*.8*g,y=-A*2.2,g*=1-A*A}const E=n.flash[c];if(d===3)this.turret.push(m,p,-x,1,0,g,y,0,xn.Static,E,0);else if(d===0)this.grunt.push(m,p,-x,1,0,g,y,n.phase[c],_,E,I);else{const A=d===2?.72:1;this.brute.push(m,p,-x,1,0,g,y,n.phase[c],_,E,I,1,A,A)}this.shadows&&h!==_e.Dying&&this.shadowAt(a++,m,u,g)}this.grunt.end(),this.brute.end(),this.turret.end(),this.shadows&&(this.shadows.count=a,this.shadows.instanceMatrix.needsUpdate=!0);const o=this.dummy;let l=0;for(let c=0;c<t.pods.cap;c++){if(!t.pods.live[c])continue;const h=(t.pods.z[c]-t.pods.startZ[c])/6.5;o.position.set(t.pods.x[c],1+Math.sin(Math.min(1,h)*Math.PI)*.9,-t.pods.z[c]),o.rotation.set((.5-h)*.6,0,0),o.scale.setScalar(1),o.updateMatrix(),this.pods.setMatrixAt(l++,o.matrix)}this.pods.count=l,this.pods.instanceMatrix.needsUpdate=!0,l=0,o.rotation.set(0,0,0);for(let c=0;c<n.boltCap;c++)n.boltLive[c]&&(o.position.set(n.boltX[c],1.2+Math.sin(n.boltT[c]*Math.PI)*1.6,-n.boltZ[c]),o.updateMatrix(),this.bolts.setMatrixAt(l++,o.matrix));this.bolts.count=l,this.bolts.instanceMatrix.needsUpdate=!0,this.drawn=this.blue.count+this.grunt.count+this.brute.count+this.turret.count}dispose(){for(const t of[this.blue,this.grunt,this.brute,this.turret])t.dispose();for(const t of[this.pods,this.bolts,this.shadows])t?.geometry.dispose(),t?.material?.dispose()}}class gh{constructor(t,e){this.cap=t,this.cursor=0,this.active=0,this.pos=new Float32Array(t*3),this.col=new Float32Array(t*3),this.size=new Float32Array(t),this.alpha=new Float32Array(t),this.vel=new Float32Array(t*3),this.life=new Float32Array(t),this.maxLife=new Float32Array(t),this.grav=new Float32Array(t);const n=new ye;n.setAttribute("position",new ge(this.pos,3).setUsage(Yn)),n.setAttribute("aColor",new ge(this.col,3).setUsage(Yn)),n.setAttribute("aSize",new ge(this.size,1).setUsage(Yn)),n.setAttribute("aAlpha",new ge(this.alpha,1).setUsage(Yn));const i=new Te({transparent:!0,depthWrite:!1,blending:e?dn:mi,uniforms:{uSoft:{value:e?1:0}},vertexShader:`attribute vec3 aColor; attribute float aSize; attribute float aAlpha; varying vec3 vC; varying float vA;
        void main(){ vC = aColor; vA = aAlpha; vec4 mv = modelViewMatrix * vec4(position, 1.0);
          gl_Position = projectionMatrix * mv; gl_PointSize = aAlpha > 0.0 ? aSize * (260.0 / -mv.z) : 0.0; }`,fragmentShader:`uniform float uSoft; varying vec3 vC; varying float vA;
        void main(){ float d = length(gl_PointCoord - 0.5);
          float a = uSoft > 0.5 ? smoothstep(0.5, 0.0, d) : 1.0;
          if (a * vA < 0.01) discard;
          gl_FragColor = vec4(vC, a * vA);
          #include <colorspace_fragment>
        }`});this.points=new _l(n,i),this.points.frustumCulled=!1,this.points.renderOrder=5}emit(t,e,n,i,s,a,o,l,c,h){const u=this.cursor;this.cursor=(u+1)%this.cap,this.pos[u*3]=t,this.pos[u*3+1]=e,this.pos[u*3+2]=n,this.vel[u*3]=i,this.vel[u*3+1]=s,this.vel[u*3+2]=a,this.col[u*3]=c.r,this.col[u*3+1]=c.g,this.col[u*3+2]=c.b,this.life[u]=this.maxLife[u]=o,this.size[u]=l,this.grav[u]=h}update(t){let e=0;for(let i=0;i<this.cap;i++){if(this.life[i]<=0)continue;const s=this.life[i]-=t;if(s<=0){this.alpha[i]=0;continue}e++;const a=i*3;this.vel[a+1]-=this.grav[i]*t,this.pos[a]+=this.vel[a]*t,this.pos[a+1]+=this.vel[a+1]*t,this.pos[a+2]+=this.vel[a+2]*t,this.pos[a+1]<.05&&this.grav[i]>0&&(this.pos[a+1]=.05,this.vel[a+1]*=-.35,this.vel[a]*=.6,this.vel[a+2]*=.6);const o=s/this.maxLife[i];this.alpha[i]=o<.5?o*2:1}this.active=e;const n=this.points.geometry;n.attributes.position.needsUpdate=!0,n.attributes.aAlpha.needsUpdate=!0,n.attributes.aColor.needsUpdate=!0,n.attributes.aSize.needsUpdate=!0}clear(){this.life.fill(0),this.alpha.fill(0)}}class cx{constructor(t){this.group=new De,this.rings=[],this.ringCursor=0,this.color=new dt,this.glow=new gh(Math.round(t*.65),!0),this.solid=new gh(Math.round(t*.35),!1),this.group.add(this.glow.points,this.solid.points);const e=new Fi(.82,1,40).rotateX(-Math.PI/2);for(let n=0;n<14;n++){const i=new Rt(e,new ne({transparent:!0,opacity:0,blending:dn,depthWrite:!1}));i.visible=!1,i.renderOrder=4,this.group.add(i),this.rings.push({mesh:i,t:0,dur:1,radius:1})}}get activeParticles(){return this.glow.active+this.solid.active}burst(t,e,n,i,s,a,o,l,c=9,h=.6,u=!1){const d=u?this.solid:this.glow;this.color.setHex(s);for(let f=0;f<i;f++){const m=Math.random()*Math.PI*2,v=Math.random()*Math.PI-Math.PI/2,g=a*(.35+Math.random()*.65),p=Math.cos(v);d.emit(t,e,n,Math.cos(m)*p*g,Math.abs(Math.sin(v))*g*h+g*h*.4,Math.sin(m)*p*g,o*(.6+Math.random()*.4),l*(.6+Math.random()*.6),this.color,c)}}puff(t,e,n,i,s,a,o=.6){this.color.setHex(i),this.glow.emit(t,e,n,(Math.random()-.5)*.6,o,(Math.random()-.5)*.6,a,s,this.color,0)}ring(t,e,n,i,s=.45,a=.08){const o=this.rings[this.ringCursor];this.ringCursor=(this.ringCursor+1)%this.rings.length,o.t=0,o.dur=s,o.radius=i,o.mesh.visible=!0,o.mesh.position.set(t,a,e),o.mesh.material.color.setHex(n)}confetti(t,e,n,i){const s=[4183551,16765498,16732064,7208842,16777215,9202687];for(let a=0;a<i;a++)this.color.setHex(s[a%s.length]),this.solid.emit(t+(Math.random()-.5)*7,e+Math.random()*2,n+(Math.random()-.5)*6,(Math.random()-.5)*5,5+Math.random()*7,(Math.random()-.5)*5,1.8+Math.random()*1.4,.16+Math.random()*.12,this.color,7)}update(t){this.glow.update(t),this.solid.update(t);for(const e of this.rings){if(!e.mesh.visible)continue;e.t+=t;const n=e.t/e.dur;if(n>=1){e.mesh.visible=!1;continue}const i=e.radius*(.15+.85*(1-(1-n)*(1-n)));e.mesh.scale.set(i,1,i),e.mesh.material.opacity=(1-n)*.9}}clear(){this.glow.clear(),this.solid.clear();for(const t of this.rings)t.mesh.visible=!1}}function Hu(r,t=!1){const e=r[0].index!==null,n=new Set(Object.keys(r[0].attributes)),i=new Set(Object.keys(r[0].morphAttributes)),s={},a={},o=r[0].morphTargetsRelative,l=new ye;let c=0;for(let h=0;h<r.length;++h){const u=r[h];let d=0;if(e!==(u.index!==null))return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index "+h+". All geometries must have compatible attributes; make sure index attribute exists among all geometries, or in none of them."),null;for(const f in u.attributes){if(!n.has(f))return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index "+h+'. All geometries must have compatible attributes; make sure "'+f+'" attribute exists among all geometries, or in none of them.'),null;s[f]===void 0&&(s[f]=[]),s[f].push(u.attributes[f]),d++}if(d!==n.size)return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index "+h+". Make sure all geometries have the same number of attributes."),null;if(o!==u.morphTargetsRelative)return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index "+h+". .morphTargetsRelative must be consistent throughout all geometries."),null;for(const f in u.morphAttributes){if(!i.has(f))return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index "+h+".  .morphAttributes must be consistent throughout all geometries."),null;a[f]===void 0&&(a[f]=[]),a[f].push(u.morphAttributes[f])}if(t){let f;if(e)f=u.index.count;else if(u.attributes.position!==void 0)f=u.attributes.position.count;else return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index "+h+". The geometry must have either an index or a position attribute"),null;l.addGroup(c,f,h),c+=f}}if(e){let h=0;const u=[];for(let d=0;d<r.length;++d){const f=r[d].index;for(let m=0;m<f.count;++m)u.push(f.getX(m)+h);h+=r[d].attributes.position.count}l.setIndex(u)}for(const h in s){const u=vh(s[h]);if(!u)return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the "+h+" attribute."),null;l.setAttribute(h,u)}for(const h in a){const u=a[h][0].length;if(u===0)break;l.morphAttributes=l.morphAttributes||{},l.morphAttributes[h]=[];for(let d=0;d<u;++d){const f=[];for(let v=0;v<a[h].length;++v)f.push(a[h][v][d]);const m=vh(f);if(!m)return console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the "+h+" morphAttribute."),null;l.morphAttributes[h].push(m)}}return l}function vh(r){let t,e,n,i=-1,s=0;for(let c=0;c<r.length;++c){const h=r[c];if(t===void 0&&(t=h.array.constructor),t!==h.array.constructor)return console.error("THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.array must be of consistent array types across matching attributes."),null;if(e===void 0&&(e=h.itemSize),e!==h.itemSize)return console.error("THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.itemSize must be consistent across matching attributes."),null;if(n===void 0&&(n=h.normalized),n!==h.normalized)return console.error("THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.normalized must be consistent across matching attributes."),null;if(i===-1&&(i=h.gpuType),i!==h.gpuType)return console.error("THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.gpuType must be consistent across matching attributes."),null;s+=h.count*e}const a=new t(s),o=new ge(a,e,n);let l=0;for(let c=0;c<r.length;++c){const h=r[c];if(h.isInterleavedBufferAttribute){const u=l/e;for(let d=0,f=h.count;d<f;d++)for(let m=0;m<e;m++){const v=h.getComponent(d,m);o.setComponent(d+u,m,v)}}else a.set(h.array,l);l+=h.count*e}return i!==void 0&&(o.gpuType=i),o}function _h(r,t){if(t===Sd)return console.warn("THREE.BufferGeometryUtils.toTrianglesDrawMode(): Geometry already defined as triangles."),r;if(t===zo||t===Kh){let e=r.getIndex();if(e===null){const a=[],o=r.getAttribute("position");if(o!==void 0){for(let l=0;l<o.count;l++)a.push(l);r.setIndex(a),e=r.getIndex()}else return console.error("THREE.BufferGeometryUtils.toTrianglesDrawMode(): Undefined position attribute. Processing not possible."),r}const n=e.count-2,i=[];if(t===zo)for(let a=1;a<=n;a++)i.push(e.getX(0)),i.push(e.getX(a)),i.push(e.getX(a+1));else for(let a=0;a<n;a++)a%2===0?(i.push(e.getX(a)),i.push(e.getX(a+1)),i.push(e.getX(a+2))):(i.push(e.getX(a+2)),i.push(e.getX(a+1)),i.push(e.getX(a)));i.length/3!==n&&console.error("THREE.BufferGeometryUtils.toTrianglesDrawMode(): Unable to generate correct amount of triangles.");const s=r.clone();return s.setIndex(i),s.clearGroups(),s}else return console.error("THREE.BufferGeometryUtils.toTrianglesDrawMode(): Unknown draw mode:",t),r}const hx={neon:{skyTop:329231,skyBottom:1773895,fog:1182771,fogNear:45,fogFar:150,sun:14674175,sunIntensity:2.6,hemiSky:10466559,hemiGround:4860524,hemiIntensity:2.4,track:"#232a47",trackLine:"#3fd5ff",accent:3133695,accent2:16726622,ground:526870,groundY:-7,ambient:"specks",ambientColor:7330047},desert:{skyTop:4165590,skyBottom:16174996,fog:15648140,fogNear:55,fogFar:170,sun:16773327,sunIntensity:2.3,hemiSky:12573951,hemiGround:12157514,hemiIntensity:1.25,track:"#b8925e",trackLine:"#f5e2b4",accent:16761690,accent2:3120088,ground:14264421,groundY:-5,ambient:"dust",ambientColor:16773327},frozen:{skyTop:1851256,skyBottom:12575487,fog:11457525,fogNear:40,fogFar:150,sun:15135743,sunIntensity:1.9,hemiSky:13625599,hemiGround:6260408,hemiIntensity:1.45,track:"#6f93bd",trackLine:"#e8f7ff",accent:10479359,accent2:3833343,ground:15135227,groundY:-5,ambient:"snow",ambientColor:16777215},cyber:{skyTop:459800,skyBottom:3805022,fog:2427461,fogNear:40,fogFar:140,sun:15785215,sunIntensity:2.4,hemiSky:13671679,hemiGround:2837114,hemiIntensity:2.3,track:"#2a2248",trackLine:"#ff4fd8",accent:16732120,accent2:3535103,ground:393999,groundY:-40,ambient:"specks",ambientColor:16747760},volcanic:{skyTop:1180933,skyBottom:6953480,fog:3804936,fogNear:38,fogFar:135,sun:16769216,sunIntensity:2.6,hemiSky:16757898,hemiGround:8006165,hemiIntensity:2.2,track:"#3a3232",trackLine:"#ff8a2a",accent:16742942,accent2:16765498,ground:1706760,groundY:-5,ambient:"embers",ambientColor:16752704}};class ux{constructor(t){this.scene=t,this.hemi=new qv,this.sun=new wu,this.sky=null,this.sun.position.set(-6,14,8),t.add(this.hemi,this.sun)}apply(t){this.hemi.color.setHex(t.hemiSky),this.hemi.groundColor.setHex(t.hemiGround),this.hemi.intensity=t.hemiIntensity,this.sun.color.setHex(t.sun),this.sun.intensity=t.sunIntensity,this.scene.fog=new pl(t.fog,t.fogNear,t.fogFar);const e=document.createElement("canvas");e.width=4,e.height=256;const n=e.getContext("2d"),i=n.createLinearGradient(0,0,0,256);i.addColorStop(0,"#"+new dt(t.skyTop).getHexString()),i.addColorStop(.55,"#"+new dt(t.skyBottom).getHexString()),i.addColorStop(1,"#"+new dt(t.fog).getHexString()),n.fillStyle=i,n.fillRect(0,0,4,256),this.sky?.dispose(),this.sky=new sr(e),this.sky.colorSpace=be,this.scene.background=this.sky}}const Qi=-14;function jt(r,t,e,n=0,i=0,s=0){return new xe(r,t,e).translate(n,i,s)}function on(r){const t=r.map(e=>{const n=e.index?e.toNonIndexed():e;return n.deleteAttribute("uv"),n});return Hu(t,!1)}function Os(r,t,e,n=!0){const i=document.createElement("canvas");i.width=r,i.height=t,e(i.getContext("2d"));const s=new sr(i);return s.colorSpace=be,n&&(s.wrapS=s.wrapT=vi),s.anisotropy=4,s}class dx{constructor(t,e){this.level=t,this.quality=e,this.group=new De,this.disposables=[],this.animated=[],this.ambient=null,this.ambientUniforms={uTime:{value:0},uOrigin:{value:new P}},this.theme=hx[t.world],this.buildTrack(),this.buildGround(),this.buildProps(t.world),this.buildAmbient()}track(t){return this.disposables.push(t),t}add(t,e){const n=new Rt(this.track(t),this.track(e));return this.group.add(n),n}buildTrack(){const{level:t,theme:e}=this,n=t.length+16,i=[];for(const R of t.obstacles)if(R.kind==="bridge"&&i.push({z0:R.z0,z1:R.z1,spans:[[R.x0,R.x1]]}),R.kind==="fallingPlatform"){const B=[];R.x0>-qt+.1&&B.push([-qt,R.x0]),R.x1<qt-.1&&B.push([R.x1,qt]),i.push({z0:R.z0,z1:R.z1,spans:B})}i.sort((R,B)=>R.z0-B.z0);const s=[];let a=Qi;for(const R of i){R.z0>a&&s.push({x0:-qt,x1:qt,z0:a,z1:R.z0});for(const[B,j]of R.spans)s.push({x0:B,x1:j,z0:R.z0,z1:R.z1});a=Math.max(a,R.z1)}s.push({x0:-qt,x1:qt,z0:a,z1:n});const o=[],l=[],c=[],h=[],u=[],d=[];for(const R of s){const B=(R.x0+qt)/(qt*2),j=(R.x1+qt)/(qt*2),X=[[R.x0,-R.z0,B,R.z0],[R.x1,-R.z0,j,R.z0],[R.x1,-R.z1,j,R.z1],[R.x0,-R.z0,B,R.z0],[R.x1,-R.z1,j,R.z1],[R.x0,-R.z1,B,R.z1]];for(const[it,lt,St,kt]of X)o.push(it,0,lt),l.push(St,kt/10),c.push(0,1,0);const Q=R.x1-R.x0,G=R.z1-R.z0;h.push(jt(Q,.7,G,(R.x0+R.x1)/2,-.36,-(R.z0+R.z1)/2));for(const it of[R.x0,R.x1]){const lt=Math.abs(Math.abs(it)-qt)<.05;lt&&u.push(jt(.3,.42,G,it+Math.sign(it)*.15,.2,-(R.z0+R.z1)/2)),d.push(jt(.09,.05,G,it+Math.sign(it)*(lt?.15:-.1),lt?.43:.03,-(R.z0+R.z1)/2))}}const f=new ye;f.setAttribute("position",new Vt(o,3)),f.setAttribute("normal",new Vt(c,3)),f.setAttribute("uv",new Vt(l,2));const m="#"+new dt(e.accent).getHexString(),v=this.track(Os(256,256,R=>{R.fillStyle=e.track,R.fillRect(0,0,256,256),R.strokeStyle="rgba(0,0,0,0.22)",R.lineWidth=2;for(let B=0;B<=256;B+=64)R.beginPath(),R.moveTo(0,B),R.lineTo(256,B),R.stroke();for(const B of[64,192])R.beginPath(),R.moveTo(B,0),R.lineTo(B,256),R.stroke();R.fillStyle="rgba(255,255,255,0.045)";for(let B=0;B<40;B++)R.fillRect(B*97%256,B*53%256,22,3);R.fillStyle=e.trackLine,R.globalAlpha=.9,R.fillRect(8,0,5,256),R.fillRect(243,0,5,256),R.globalAlpha=.55,R.fillRect(126,20,4,90),R.fillRect(126,148,4,90),R.globalAlpha=1})),g=this.track(Os(256,256,R=>{R.fillStyle="#000",R.fillRect(0,0,256,256),R.fillStyle=m,R.fillRect(8,0,5,256),R.fillRect(243,0,5,256),R.globalAlpha=.6,R.fillRect(126,20,4,90),R.fillRect(126,148,4,90)})),p=this.level.world!=="desert"&&this.level.world!=="frozen";this.add(f,new Ke({map:v,emissiveMap:g,emissive:16777215,emissiveIntensity:p?1.4:.25})),this.add(on(h),new Ke({color:new dt(e.track).multiplyScalar(.55)})),this.add(on(u),new Ke({color:new dt(e.track).multiplyScalar(1.5)}));const x=new ne({color:e.accent});this.add(on(d),x);const y=this.track(Os(64,64,R=>{R.clearRect(0,0,64,64),R.strokeStyle="#fff",R.lineWidth=7,R.lineJoin="miter",R.beginPath(),R.moveTo(10,44),R.lineTo(32,22),R.lineTo(54,44),R.stroke()}));y.repeat.set(1,n/5);const _=new ne({map:y,color:e.accent,transparent:!0,opacity:.32,depthWrite:!1,blending:dn}),I=this.add(new We(1.6,n-Qi).rotateX(-Math.PI/2),_);I.position.set(0,.025,-(n+Qi)/2),I.renderOrder=1,this.animated.push(R=>{y.offset.y=R*.9,x.color.setHex(e.accent).multiplyScalar(.8+Math.sin(R*3)*.2)});const E=this.track(jt(1.2,1,1.2,0,-.5,0)),A=this.track(new Ke({color:new dt(e.track).multiplyScalar(.4)})),C=Math.floor((n-Qi)/22)*2,b=new Ni(E,A,C),M=new he;for(let R=0;R<C;R++)M.position.set((R%2?1:-1)*3.6,-.7,-(Qi+8+Math.floor(R/2)*22)),M.scale.set(1,Math.min(60,-e.groundY),1),M.updateMatrix(),b.setMatrixAt(R,M.matrix);this.group.add(b);const L=this.add(new Qe(9.5,10.5,.7,24).translate(0,-.37,-t.length),new Ke({color:new dt(e.track).multiplyScalar(.8)}));L.renderOrder=-1;const z=this.add(new Fi(8.6,9.1,48).rotateX(-Math.PI/2).translate(0,.02,-t.length),new ne({color:e.accent2,transparent:!0,opacity:.8}));this.animated.push(R=>z.material.opacity=.55+Math.sin(R*2.5)*.25)}buildGround(){const{theme:t,level:e}=this,n=e.length+260;if(e.world==="volcanic"){const a={uTime:{value:0},fogColor:{value:new dt(t.fog)},fogNear:{value:t.fogNear},fogFar:{value:t.fogFar}},o=new Te({uniforms:a,vertexShader:`varying vec2 vP; varying float vDepth;
          void main(){ vec4 w = modelMatrix * vec4(position,1.0); vP = w.xz; vec4 mv = viewMatrix * w; vDepth = -mv.z; gl_Position = projectionMatrix * mv; }`,fragmentShader:`uniform float uTime; uniform vec3 fogColor; uniform float fogNear; uniform float fogFar;
          varying vec2 vP; varying float vDepth;
          float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
          float noise(vec2 p){ vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
            return mix(mix(hash(i),hash(i+vec2(1,0)),f.x), mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x), f.y); }
          void main(){
            vec2 p = vP * 0.11;
            float n = noise(p + vec2(0.0, uTime*0.05)) * 0.6 + noise(p*2.3 - vec2(uTime*0.04, 0.0)) * 0.4;
            float crack = smoothstep(0.42, 0.62, n);
            vec3 col = mix(vec3(0.07,0.02,0.015), vec3(1.0,0.36,0.05), crack);
            col += vec3(1.0,0.85,0.3) * smoothstep(0.72, 0.9, n);
            float fog = smoothstep(fogNear, fogFar, vDepth);
            gl_FragColor = vec4(mix(col, fogColor, fog), 1.0);
            #include <colorspace_fragment>
          }`});this.add(new We(260,n).rotateX(-Math.PI/2),o).position.set(0,t.groundY,-e.length/2),this.animated.push(c=>a.uTime.value=c);return}const i=this.track(Os(128,128,a=>{const o=new dt(t.ground);if(a.fillStyle="#"+o.getHexString(),a.fillRect(0,0,128,128),e.world==="neon"||e.world==="cyber")a.strokeStyle="#"+new dt(t.accent).multiplyScalar(.5).getHexString(),a.lineWidth=2,a.strokeRect(0,0,128,128);else for(let l=0;l<220;l++)a.fillStyle=l%2?"rgba(255,255,255,0.06)":"rgba(0,0,0,0.05)",a.fillRect(l*71%128,l*37%128,10+l%5*4,2)}));i.repeat.set(40,n/6),this.add(new We(260,n).rotateX(-Math.PI/2),new Ke({map:i})).position.set(0,t.groundY,-e.length/2)}scatter(t,e,n,i,s,a){const o=Math.max(1,Math.round(n*this.quality.propDensity)),l=new Ni(this.track(t),this.track(e),o),c=new he,h=new dt,u=this.level.length+110;for(let d=0;d<o;d++)c.position.set(0,0,0),c.rotation.set(0,0,0),c.scale.set(1,1,1),s(i,d%2?1:-1,Qi-6+(d+i.next())/o*u,c),c.updateMatrix(),l.setMatrixAt(d,c.matrix),a&&l.setColorAt(d,h.setHex(i.pick(a)));this.group.add(l)}buildProps(t){const{theme:e}=this,n=new ea(this.level.seed*31+7),i=e.groundY,s=(c,h={})=>new Ke({color:c,flatShading:!0,...h}),a=c=>new ne({color:c}),o=(c,h=.9)=>new ne({color:c,transparent:!0,opacity:h,blending:dn,depthWrite:!1,side:hn}),l=(c,h,u,d)=>h*c.range(u,d);if(t==="neon"){const c=on([jt(.35,7,.35,0,3.5,0),jt(2.6,.3,.4,-1.15,7,0),jt(.7,.5,.7,0,.25,0)]);this.scatter(c,s(3817574),24,n,(u,d,f,m)=>{m.position.set(d*6.5,0,-Math.round(f/14)*14),m.scale.x=d});for(const[u,d]of[[e.accent,0],[e.accent2,14]])this.scatter(jt(2,.1,.24,-1.3,6.8,0),a(u),12,n,(f,m,v,g)=>{g.position.set(m*6.5,0,-Math.round(v/28)*28-d),g.scale.x=m});const h=on([jt(2.4,1,.7,0,.5,0),jt(2.6,.2,.9,0,1.1,0)]);this.scatter(h,s(16777215),60,n,(u,d,f,m)=>{m.position.set(l(u,d,7.2,8.4),i+7,-f),m.rotation.y=u.range(-.1,.1)},[3883619,2896720,5587054]),this.scatter(jt(1,1,1,0,.5,0),s(16777215),70,n,(u,d,f,m)=>{m.position.set(l(u,d,11,46),i,-f),m.scale.set(u.range(3,8),u.range(5,26),u.range(3,8))},[1448755,1906496,1056826]),this.scatter(new We(5,2.6),o(16777215,.75),16,n,(u,d,f,m)=>{m.position.set(l(u,d,9,20),u.range(3,12),-f),m.rotation.y=-d*u.range(.5,1.1)},[e.accent,e.accent2,10316799])}else if(t==="desert"){const c=[13608042,12160341,14728064],h=on([new Qe(.75,.9,7,8).translate(0,3.5,0),jt(2.2,.5,2.2,0,7.25,0),jt(2.4,.5,2.4,0,.25,0)]);this.scatter(h,s(16777215),34,n,(d,f,m,v)=>{v.position.set(l(d,f,7.5,20),i,-m),v.scale.y=d.next()<.4?d.range(.3,.6):d.range(.9,1.5),v.rotation.z=d.range(-.06,.06)},c);const u=on([jt(1.6,9,1.6,-4,4.5,0),jt(1.6,9,1.6,4,4.5,0),jt(11,1.6,2,0,9.8,0),jt(8,.8,1.6,0,11,0)]);this.scatter(u,s(16777215),8,n,(d,f,m,v)=>{v.position.set(l(d,f,14,30),i,-m),v.rotation.y=d.range(0,3),v.scale.setScalar(d.range(.9,1.6))},c),this.scatter(new Sl(1,0),s(16777215),70,n,(d,f,m,v)=>{v.position.set(l(d,f,7,50),i,-m),v.scale.set(d.range(1,4),d.range(.8,3),d.range(1,4)),v.rotation.set(d.next(),d.next()*3,d.next())},[10187846,11569752,8346936]),this.scatter(new Qe(.7,1,1,7).translate(0,.5,0),s(16777215),14,n,(d,f,m,v)=>{v.position.set(l(d,f,48,95),i,-m),v.scale.set(d.range(14,30),d.range(14,34),d.range(14,30))},[11892298,10708029]),this.scatter(new Qr(4,.9,6,14),s(5199200),10,n,(d,f,m,v)=>{v.position.set(l(d,f,10,34),i+d.range(-1,1.5),-m),v.rotation.set(d.range(.2,1.2),d.next()*3,d.range(-.4,.4)),v.scale.setScalar(d.range(.6,1.5))}),this.scatter(jt(1.2,1.2,14),s(6120302),8,n,(d,f,m,v)=>{v.position.set(l(d,f,9,30),i+1.5,-m),v.rotation.set(d.range(-.5,.5),d.next()*3,0)})}else if(t==="frozen"){const c=new Ke({color:16777215,flatShading:!0,emissive:2781104,emissiveIntensity:.55,transparent:!0,opacity:.9});this.scatter(new wl(1,0),c,60,n,(f,m,v,g)=>{g.position.set(l(f,m,7,36),i+f.range(0,1.5),-v),g.scale.set(f.range(.8,2.2),f.range(3,9),f.range(.8,2.2)),g.rotation.set(f.range(-.3,.3),f.next()*3,f.range(-.3,.3))},[12577279,9425151,15137023]);const h=on([jt(11,7,2.4,0,3.5,0),...[-4,-1.35,1.35,4].map(f=>jt(1.6,1.2,2.4,f,7.6,0)),jt(3.4,10.5,3.4,5.6,5.25,0),jt(4,.8,4,5.6,10.9,0)]);this.scatter(h,s(16777215),22,n,(f,m,v,g)=>{g.position.set(m*f.range(13,15),i,-Math.round(v/11)*11),g.rotation.y=m*Math.PI/2},[9086663,10336214]);const u=on([jt(1.6,20,1.6,-7,10,0),jt(1.6,20,1.6,7,10,0),jt(15.6,1.4,1.8,0,20.4,0),...[-4.5,-1.5,1.5,4.5].map(f=>new ns(.5,2.6,5).rotateX(Math.PI).translate(f,18.5,0))]);this.scatter(u,c,5,n,(f,m,v,g)=>g.position.set(0,0,-Math.round(v/40)*40-20),[13627647]);const d=on([new Qe(.25,.3,1.2,6).translate(0,.6,0),new ns(1.7,2.6,7).translate(0,2.3,0),new ns(1.3,2.3,7).translate(0,3.8,0),new ns(.8,2,7).translate(0,5.1,0)]);this.scatter(d,s(16777215),60,n,(f,m,v,g)=>{g.position.set(l(f,m,18,60),i,-v),g.scale.setScalar(f.range(.8,1.8))},[14675706,12901616,10470110]),this.scatter(new ys(1,8,5),s(16054783),40,n,(f,m,v,g)=>{g.position.set(l(f,m,7,40),i-.3,-v),g.scale.set(f.range(2,7),f.range(.8,2),f.range(2,7))})}else if(t==="cyber"){const c=this.track(Os(64,128,m=>{m.fillStyle="#05040c",m.fillRect(0,0,64,128);for(let v=4;v<128;v+=8)for(let g=4;g<64;g+=8){const p=Math.sin(g*12.9+v*78.2)*43758.5,x=p-Math.floor(p);x>.45&&(m.fillStyle=x>.85?"#ff7be6":x>.65?"#5ff2ff":"#3a2c6e",m.fillRect(g,v,4,5))}})),h=new xe(1,1,1).translate(0,.5,0),u=new Ke({color:1380394,emissive:16777215,emissiveMap:c,emissiveIntensity:1.5});this.scatter(h,u,90,n,(m,v,g,p)=>{p.position.set(l(m,v,10,70),i,-g),p.scale.set(m.range(5,12),m.range(34,78),m.range(5,12))});const d=o(16777215,.6),f=o(e.accent2,.55);this.scatter(new We(6,3.4),d,22,n,(m,v,g,p)=>{p.position.set(l(m,v,8.5,22),m.range(2,16),-g),p.rotation.y=-v*m.range(.4,1.2)},[e.accent,e.accent2,16769359]),this.scatter(new Qr(2.2,.08,6,28),f,12,n,(m,v,g,p)=>{p.position.set(l(m,v,9,18),m.range(4,14),-g),p.rotation.set(m.next()*3,m.next()*3,0)}),this.animated.push(m=>{d.opacity=.5+(Math.sin(m*9)>.92?-.3:0)+Math.sin(m*1.7)*.1,f.opacity=.4+Math.sin(m*2.3)*.2}),this.scatter(on([jt(.3,3,.3,0,1.5,0),jt(1.6,.25,.3,.65,3,0)]),s(2761030),30,n,(m,v,g,p)=>{p.position.set(v*6,0,-Math.round(g/12)*12),p.scale.x=-v}),this.scatter(jt(.9,.1,.34,0,2.86,0),a(e.accent2),30,n,(m,v,g,p)=>p.position.set(v*5.1,0,-Math.round(g/12)*12))}else{this.scatter(new Qe(1,1.15,1,6).translate(0,.5,0),s(16777215),90,n,(u,d,f,m)=>{m.position.set(l(u,d,7.5,50),i-1,-f),m.scale.set(u.range(1.2,3.4),u.range(3,15),u.range(1.2,3.4)),m.rotation.y=u.next()*3},[1906454,2760992,1249039]);const c=on([jt(9,.6,7,0,5.3,0),...[[-4,-3],[4,-3],[-4,3],[4,3]].map(([u,d])=>jt(.6,5.2,.6,u,2.6,d)),jt(3.4,3.6,3.4,-1.6,7.4,0),new Qe(1.2,1.2,4.6,10).translate(2.4,7.9,0)]);this.scatter(c,s(16777215),12,n,(u,d,f,m)=>{m.position.set(l(u,d,13,30),i,-f),m.rotation.y=u.next()*3},[4867908,3815478,5917248]),this.scatter(new Qe(.5,.5,26,8).rotateX(Math.PI/2),s(5525580),14,n,(u,d,f,m)=>{m.position.set(l(u,d,8,12),i+u.range(1.5,4),-f)});const h=o(e.accent,.95);this.scatter(new Qe(.9,1.3,.5,8),h,30,n,(u,d,f,m)=>{m.position.set(l(u,d,7.5,34),i+.3,-f),m.scale.setScalar(u.range(.7,2))}),this.scatter(jt(.2,.5,5,0,-.4,0),a(e.accent),40,n,(u,d,f,m)=>m.position.set(d*5.02,0,-Math.round(f/8)*8)),this.animated.push(u=>h.opacity=.7+Math.sin(u*4.3)*.25)}}buildAmbient(){const t=this.quality.ambientParticles;if(t===0)return;const{theme:e}=this,n=new Float32Array(t*3),i=new Float32Array(t),s=new ea(99);for(let c=0;c<t;c++)n[c*3]=s.range(0,1),n[c*3+1]=s.range(0,1),n[c*3+2]=s.range(0,1),i[c]=s.next();const a=this.track(new ye);a.setAttribute("position",new ge(n,3)),a.setAttribute("aSeed",new ge(i,1));const o={specks:[.2,.25,0],dust:[1.2,.1,.3],snow:[.5,-1.6,.2],embers:[.3,1.5,0]},l=this.track(new Te({uniforms:{...this.ambientUniforms,uColor:{value:new dt(e.ambientColor)},uDrift:{value:new P(...o[e.ambient])}},transparent:!0,depthWrite:!1,blending:e.ambient==="snow"||e.ambient==="dust"?mi:dn,vertexShader:`attribute float aSeed; uniform float uTime; uniform vec3 uOrigin; uniform vec3 uDrift; varying float vA;
        void main(){
          vec3 size = vec3(34.0, 16.0, 60.0);
          vec3 p = position * size + uDrift * uTime * (0.5 + aSeed);
          p.x += sin(uTime * 0.7 + aSeed * 40.0) * 0.6;
          p = mod(p - uOrigin, size) - size * vec3(0.5, 0.2, 0.85) + uOrigin;
          vec4 mv = viewMatrix * vec4(p, 1.0);
          gl_Position = projectionMatrix * mv;
          gl_PointSize = (2.0 + aSeed * 5.0) * (30.0 / -mv.z);
          vA = 0.35 + 0.5 * aSeed;
        }`,fragmentShader:`uniform vec3 uColor; varying float vA;
        void main(){ float d = length(gl_PointCoord - 0.5); if (d > 0.5) discard; gl_FragColor = vec4(uColor, vA * smoothstep(0.5, 0.1, d));
        #include <colorspace_fragment>
        }`}));this.ambient=new _l(a,l),this.ambient.frustumCulled=!1,this.group.add(this.ambient)}update(t,e,n){for(const i of this.animated)i(t,e);this.ambientUniforms.uTime.value=t,this.ambientUniforms.uOrigin.value.copy(n)}dispose(){for(const t of this.disposables)t.dispose();this.group.removeFromParent()}}function fx(r){return r.kind==="sub"?16726843:r.kind==="div"?12718895:r.kind==="add"?r.value>=25?1695944:r.value>=10?3138426:r.value>=5?9431098:13166138:r.value>=100?16765471:r.value>=10?16742938:r.value>=5?16727972:r.value>=3?10771711:4033535}const xh=new Map;function px(r){let t=xh.get(r);if(t)return t;const e=document.createElement("canvas");e.width=256,e.height=128;const n=e.getContext("2d");return n.font=`900 ${r.length>3?84:104}px system-ui, -apple-system, "Segoe UI", Roboto, sans-serif`,n.textAlign="center",n.textBaseline="middle",n.lineJoin="round",n.lineWidth=14,n.strokeStyle="rgba(8,12,30,0.85)",n.strokeText(r,128,68),n.fillStyle="#fff",n.fillText(r,128,68),t=new sr(e),t.colorSpace=be,xh.set(r,t),t}const mx="varying vec2 vUv; void main(){ vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }",gx=`
uniform vec3 uColor; uniform float uTime; uniform float uFlash; uniform float uCharge;
varying vec2 vUv;
void main(){
  // glass: faint fill, rising scan lines, bright animated border
  vec2 e = min(vUv, 1.0 - vUv);
  float border = 1.0 - smoothstep(0.0, 0.07, min(e.x * 2.2, e.y));
  float run = 0.5 + 0.5 * sin((vUv.x + vUv.y) * 18.0 - uTime * 6.0);
  float scan = smoothstep(0.92, 1.0, fract(vUv.y * 7.0 - uTime * 0.8));
  float sheen = smoothstep(0.35, 0.0, abs(vUv.x - vUv.y * 0.6 - fract(uTime * 0.25) * 2.0 + 0.6));
  float a = 0.20 + border * (0.55 + 0.35 * run) + scan * 0.12 + sheen * 0.10 + uFlash * 0.5;
  // an additive gate that is recharging fills from the bottom
  float ready = step(vUv.y, uCharge);
  a *= mix(0.3, 1.0, ready);
  vec3 col = mix(uColor, vec3(1.0), border * 0.45 + uFlash * 0.6);
  gl_FragColor = vec4(col, a);
  #include <colorspace_fragment>
}`;class vx{constructor(t){this.gates=t,this.group=new De,this.meshes=[],this.time={value:0};const e=3.4;for(const n of t){const i=n.def.width,s=new dt(fx(n.def.op)),a=new De,o={uColor:{value:s},uTime:this.time,uFlash:{value:0},uCharge:{value:1}},l=new Rt(new We(i,e),new Te({uniforms:o,vertexShader:mx,fragmentShader:gx,transparent:!0,depthWrite:!1,side:hn}));l.position.y=e/2+.1,l.renderOrder=3;const c=new ne({color:s}),h=new xe(.22,e+.5,.3),u=new Rt(h,c);u.position.set(-i/2,e/2+.1,0);const d=new Rt(h,c);d.position.set(i/2,e/2+.1,0);const f=new Rt(new xe(i+.22,.26,.3),c);f.position.y=e+.35;const m=new Rt(new xe(i+.6,.08,.7),new ne({color:s.clone().multiplyScalar(.5)}));m.position.y=.04;const v=new Rt(new We(Math.min(i*.82,3.4),Math.min(i*.82,3.4)/2),new ne({map:px(Du(n.def.op)),transparent:!0,depthWrite:!1}));v.position.set(0,e/2+.25,.06),v.renderOrder=4,a.add(l,u,d,f,m,v),a.position.set(n.x,0,-n.def.z),this.group.add(a),this.meshes.push({group:a,uniforms:o,label:v,frame:c})}}update(t,e){this.time.value=t;for(let n=0;n<this.gates.length;n++){const i=this.gates[n],s=this.meshes[n],a=i.def.z-e;if(s.group.visible=a>-2&&a<95,!s.group.visible)continue;s.group.position.x=i.x,s.uniforms.uFlash.value=i.flash;const o=i.def.op.kind,l=o==="add"||o==="sub"?1-i.cooldown/Xo:1;s.uniforms.uCharge.value=l>=1?2:l,s.label.material.opacity=l>=1?1:.4;const c=1+i.flash*.12;s.group.scale.set(c,c,1)}}dispose(){this.group.traverse(t=>{const e=t;e.isMesh&&(e.geometry.dispose(),e.material.dispose())}),this.group.removeFromParent()}}const Gn=16723245,qr=16761375;function _x(){const r=document.createElement("canvas");r.width=r.height=64;const t=r.getContext("2d");t.fillStyle="#16161c",t.fillRect(0,0,64,64),t.fillStyle="#ffc21f";for(let n=-64;n<128;n+=32)t.beginPath(),t.moveTo(n,64),t.lineTo(n+16,64),t.lineTo(n+80,0),t.lineTo(n+64,0),t.fill();const e=new sr(r);return e.colorSpace=be,e.wrapS=e.wrapT=vi,e}function kr(r,t){const e=new Rt(new We(r,t).rotateX(-Math.PI/2),new ne({color:qr,transparent:!0,opacity:.2,depthWrite:!1}));return e.position.y=.03,e.renderOrder=2,e}class xx{constructor(t,e,n){this.group=new De,this.updaters=[],this.hazard=_x();const i=new Ke({color:4869980,flatShading:!0}),s=new Ke({map:this.hazard}),a=o=>new ne({color:o});for(const o of t){const l=o.def,c=new De;switch(this.group.add(c),l.kind){case"movingWall":{const h=new Rt(new xe(l.width,2.4,.8),s);h.position.y=1.2;const u=new Rt(new xe(l.width+.1,.16,.9),a(Gn));u.position.y=2.46;const d=new Rt(new xe(qt*2,.08,.3),i);d.position.set(0,.04,0);const f=kr(l.width,1.6);c.add(h,u,f),this.group.add(d),d.position.z=-l.z,c.position.z=-l.z,this.updaters.push(m=>{c.position.x=o.x,f.material.color.setHex(Gn),f.material.opacity=.25+Math.sin(m*8)*.1});break}case"blade":{const h=new Rt(new Qe(.42,.5,.9,10),i);h.position.y=.45;const u=new De,d=new Rt(new xe(l.radius*2,.12,.5),new Ke({color:13620964})),f=new Rt(new xe(l.radius*2,.05,.62),a(Gn));u.add(d,f),u.position.y=.7;const m=new Rt(new Fi(l.radius-.12,l.radius,40).rotateX(-Math.PI/2),new ne({color:Gn,transparent:!0,opacity:.6,depthWrite:!1}));m.position.y=.03;const v=new Rt(new la(l.radius,32).rotateX(-Math.PI/2),new ne({color:Gn,transparent:!0,opacity:.1,depthWrite:!1}));v.position.y=.025,c.add(h,u,m,v),c.position.set(l.x,0,-l.z),this.updaters.push(()=>u.rotation.y=o.angle);break}case"crusher":{const h=new xe(.4,5,.4);for(const g of[-1,1]){const p=new Rt(h,i);p.position.set(g*(l.width/2+.25),2.5,0),c.add(p)}const u=new Rt(new xe(l.width+.9,.5,.8),i);u.position.y=5.1;const d=new Rt(new xe(l.width,1.6,l.depth),s),f=new Rt(new xe(.5,4,.5),i),m=kr(l.width,l.depth);c.add(u,d,f,m),c.position.set(l.x,0,-l.z);const v=m.material;this.updaters.push(g=>{d.position.y=.8+o.y*2.6,f.position.y=d.position.y+2.6,v.color.setHex(o.danger===2?Gn:qr),v.opacity=o.danger===0?.14:o.danger===1?.35+Math.sin(g*22)*.25:.6});break}case"laser":{const h=l.x1-l.x0,u=(l.x0+l.x1)/2,d=new Qe(.22,.3,1.5,8);for(const x of[l.x0,l.x1]){const y=new Rt(d,i);y.position.set(x-u,.75,0);const _=new Rt(new ys(.2,8,6),a(Gn));_.position.set(x-u,1,0),c.add(y,_)}const f=new ne({color:Gn,transparent:!0,blending:dn,depthWrite:!1}),m=new Rt(new xe(h,.16,.16),f);m.position.y=.9;const v=new Rt(new xe(h,.5,.5),f.clone());v.position.y=.9;const g=kr(h,.5);c.add(m,v,g),c.position.set(u,0,-l.z);const p=g.material;this.updaters.push(x=>{const y=o.danger===2;m.visible=o.danger>0,f.opacity=y?1:Math.sin(x*30)>0?.35:.08,m.scale.y=m.scale.z=y?1+Math.sin(x*40)*.2:.3,v.visible=y,v.material.opacity=.22,p.color.setHex(y?Gn:qr),p.opacity=y?.5:o.danger===1?.4:.12});break}case"bridge":{const h=l.x1-l.x0,u=(l.x0+l.x1)/2,d=kr(h-.6,1.2);d.material.color.setHex(4183551),d.position.set(u,.03,-(l.z0-2.5)),c.add(d);const f=new xe(.2,1.1,.2);for(const v of[l.x0,l.x1])for(const g of[l.z0,l.z1]){const p=new Rt(f,a(qr));p.position.set(v,.55,-g),c.add(p)}const m=d.material;this.updaters.push(v=>m.opacity=.3+Math.sin(v*5)*.15);break}case"fallingPlatform":{const h=l.x1-l.x0,u=l.z1-l.z0,d=new Ke({color:new dt(n).multiplyScalar(.75)}),f=new Rt(new xe(h-.08,.5,u-.08),d),m=new Rt(new We(h-.5,u-.5).rotateX(-Math.PI/2),new ne({map:this.hazard,transparent:!0,opacity:.55,depthWrite:!1}));m.position.y=.27,f.add(m),c.add(f);const v=new P((l.x0+l.x1)/2,-.25,-(l.z0+l.z1)/2);let g=0;this.updaters.push(p=>{if(o.stage===2)g+=.016,f.position.set(v.x,v.y-g*g*18,v.z),f.rotation.z=g*.8,f.visible=g<2;else{const x=o.stage===1?.07:0;f.position.set(v.x+Math.sin(p*60)*x,v.y+Math.sin(p*47)*x,v.z),d.emissive.setHex(o.stage===1?6690048:0)}});break}case"barrel":{const h=e.model("barrel");h.scale.setScalar(1.15);const u=new Rt(new Fi(.75,.9,24).rotateX(-Math.PI/2),new ne({color:16742938,transparent:!0,opacity:.7,depthWrite:!1}));u.position.y=.03,c.add(h,u),c.position.set(l.x,0,-l.z),this.updaters.push(d=>{c.visible=o.stage===0,u.scale.setScalar(1+(Math.sin(d*5)*.5+.5)*.25)});break}}}}update(t){for(const e of this.updaters)e(t)}dispose(){this.hazard.dispose(),this.group.traverse(t=>{const e=t;e.isMesh&&(e.geometry.dispose(),e.material.dispose())}),this.group.removeFromParent()}}const yx=`
uniform float uT; uniform float uShape; uniform vec2 uSize;
varying vec2 vUv;
void main(){
  vec2 p = vUv * 2.0 - 1.0;
  float d = uShape < 0.5 ? length(p) : max(abs(p.x), abs(p.y));
  if (d > 1.0) discard;
  // the fill grows from the centre and reaches the rim exactly when the attack lands
  float fill = step(d, uT);
  float rim = smoothstep(0.86, 1.0, d);
  float blink = 0.75 + 0.25 * sin(uT * 40.0);
  float a = 0.16 + fill * 0.34 * blink + rim * 0.7;
  gl_FragColor = vec4(mix(vec3(1.0, 0.72, 0.1), vec3(1.0, 0.12, 0.08), uT), a);
  #include <colorspace_fragment>
}`;class Mx{constructor(t){this.telegraphs=t,this.group=new De,this.meshes=[];const e=new We(2,2).rotateX(-Math.PI/2);for(let n=0;n<t.length;n++){const i=new Te({uniforms:{uT:{value:0},uShape:{value:0},uSize:{value:new nt}},vertexShader:"varying vec2 vUv; void main(){ vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }",fragmentShader:yx,transparent:!0,depthWrite:!1}),s=new Rt(e,i);s.renderOrder=2,s.visible=!1,this.meshes.push(s),this.group.add(s)}}update(){for(let t=0;t<this.telegraphs.length;t++){const e=this.telegraphs[t],n=this.meshes[t];if(n.visible=e.live,!e.live)continue;n.position.set(e.x,.04,-e.z),n.scale.set(e.hw,1,e.shape===0?e.hw:e.hd);const i=n.material.uniforms;i.uT.value=Math.min(1,e.t/e.delay),i.uShape.value=e.shape}}dispose(){this.meshes[0]?.geometry.dispose();for(const t of this.meshes)t.material.dispose();this.group.removeFromParent()}}const Vu={name:"CopyShader",uniforms:{tDiffuse:{value:null},opacity:{value:1}},vertexShader:`

		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}`,fragmentShader:`

		uniform float opacity;

		uniform sampler2D tDiffuse;

		varying vec2 vUv;

		void main() {

			vec4 texel = texture2D( tDiffuse, vUv );
			gl_FragColor = opacity * texel;


		}`};class ws{constructor(){this.isPass=!0,this.enabled=!0,this.needsSwap=!0,this.clear=!1,this.renderToScreen=!1}setSize(){}render(){console.error("THREE.Pass: .render() must be implemented in derived pass.")}dispose(){}}const bx=new aa(-1,1,1,-1,0,1);class Sx extends ye{constructor(){super(),this.setAttribute("position",new Vt([-1,3,0,-1,-1,0,3,-1,0],3)),this.setAttribute("uv",new Vt([0,2,0,0,2,0],2))}}const wx=new Sx;class Cl{constructor(t){this._mesh=new Rt(wx,t)}dispose(){this._mesh.geometry.dispose()}render(t){t.render(this._mesh,bx)}get material(){return this._mesh.material}set material(t){this._mesh.material=t}}class Tx extends ws{constructor(t,e){super(),this.textureID=e!==void 0?e:"tDiffuse",t instanceof Te?(this.uniforms=t.uniforms,this.material=t):t&&(this.uniforms=Js.clone(t.uniforms),this.material=new Te({name:t.name!==void 0?t.name:"unspecified",defines:Object.assign({},t.defines),uniforms:this.uniforms,vertexShader:t.vertexShader,fragmentShader:t.fragmentShader})),this.fsQuad=new Cl(this.material)}render(t,e,n){this.uniforms[this.textureID]&&(this.uniforms[this.textureID].value=n.texture),this.fsQuad.material=this.material,this.renderToScreen?(t.setRenderTarget(null),this.fsQuad.render(t)):(t.setRenderTarget(e),this.clear&&t.clear(t.autoClearColor,t.autoClearDepth,t.autoClearStencil),this.fsQuad.render(t))}dispose(){this.material.dispose(),this.fsQuad.dispose()}}class yh extends ws{constructor(t,e){super(),this.scene=t,this.camera=e,this.clear=!0,this.needsSwap=!1,this.inverse=!1}render(t,e,n){const i=t.getContext(),s=t.state;s.buffers.color.setMask(!1),s.buffers.depth.setMask(!1),s.buffers.color.setLocked(!0),s.buffers.depth.setLocked(!0);let a,o;this.inverse?(a=0,o=1):(a=1,o=0),s.buffers.stencil.setTest(!0),s.buffers.stencil.setOp(i.REPLACE,i.REPLACE,i.REPLACE),s.buffers.stencil.setFunc(i.ALWAYS,a,4294967295),s.buffers.stencil.setClear(o),s.buffers.stencil.setLocked(!0),t.setRenderTarget(n),this.clear&&t.clear(),t.render(this.scene,this.camera),t.setRenderTarget(e),this.clear&&t.clear(),t.render(this.scene,this.camera),s.buffers.color.setLocked(!1),s.buffers.depth.setLocked(!1),s.buffers.color.setMask(!0),s.buffers.depth.setMask(!0),s.buffers.stencil.setLocked(!1),s.buffers.stencil.setFunc(i.EQUAL,1,4294967295),s.buffers.stencil.setOp(i.KEEP,i.KEEP,i.KEEP),s.buffers.stencil.setLocked(!0)}}class Ex extends ws{constructor(){super(),this.needsSwap=!1}render(t){t.state.buffers.stencil.setLocked(!1),t.state.buffers.stencil.setTest(!1)}}class Ax{constructor(t,e){if(this.renderer=t,this._pixelRatio=t.getPixelRatio(),e===void 0){const n=t.getSize(new nt);this._width=n.width,this._height=n.height,e=new fn(this._width*this._pixelRatio,this._height*this._pixelRatio,{type:Pn}),e.texture.name="EffectComposer.rt1"}else this._width=e.width,this._height=e.height;this.renderTarget1=e,this.renderTarget2=e.clone(),this.renderTarget2.texture.name="EffectComposer.rt2",this.writeBuffer=this.renderTarget1,this.readBuffer=this.renderTarget2,this.renderToScreen=!0,this.passes=[],this.copyPass=new Tx(Vu),this.copyPass.material.blending=$n,this.clock=new Qv}swapBuffers(){const t=this.readBuffer;this.readBuffer=this.writeBuffer,this.writeBuffer=t}addPass(t){this.passes.push(t),t.setSize(this._width*this._pixelRatio,this._height*this._pixelRatio)}insertPass(t,e){this.passes.splice(e,0,t),t.setSize(this._width*this._pixelRatio,this._height*this._pixelRatio)}removePass(t){const e=this.passes.indexOf(t);e!==-1&&this.passes.splice(e,1)}isLastEnabledPass(t){for(let e=t+1;e<this.passes.length;e++)if(this.passes[e].enabled)return!1;return!0}render(t){t===void 0&&(t=this.clock.getDelta());const e=this.renderer.getRenderTarget();let n=!1;for(let i=0,s=this.passes.length;i<s;i++){const a=this.passes[i];if(a.enabled!==!1){if(a.renderToScreen=this.renderToScreen&&this.isLastEnabledPass(i),a.render(this.renderer,this.writeBuffer,this.readBuffer,t,n),a.needsSwap){if(n){const o=this.renderer.getContext(),l=this.renderer.state.buffers.stencil;l.setFunc(o.NOTEQUAL,1,4294967295),this.copyPass.render(this.renderer,this.writeBuffer,this.readBuffer,t),l.setFunc(o.EQUAL,1,4294967295)}this.swapBuffers()}yh!==void 0&&(a instanceof yh?n=!0:a instanceof Ex&&(n=!1))}}this.renderer.setRenderTarget(e)}reset(t){if(t===void 0){const e=this.renderer.getSize(new nt);this._pixelRatio=this.renderer.getPixelRatio(),this._width=e.width,this._height=e.height,t=this.renderTarget1.clone(),t.setSize(this._width*this._pixelRatio,this._height*this._pixelRatio)}this.renderTarget1.dispose(),this.renderTarget2.dispose(),this.renderTarget1=t,this.renderTarget2=t.clone(),this.writeBuffer=this.renderTarget1,this.readBuffer=this.renderTarget2}setSize(t,e){this._width=t,this._height=e;const n=this._width*this._pixelRatio,i=this._height*this._pixelRatio;this.renderTarget1.setSize(n,i),this.renderTarget2.setSize(n,i);for(let s=0;s<this.passes.length;s++)this.passes[s].setSize(n,i)}setPixelRatio(t){this._pixelRatio=t,this.setSize(this._width,this._height)}dispose(){this.renderTarget1.dispose(),this.renderTarget2.dispose(),this.copyPass.dispose()}}const Rx={name:"OutputShader",uniforms:{tDiffuse:{value:null},toneMappingExposure:{value:1}},vertexShader:`
		precision highp float;

		uniform mat4 modelViewMatrix;
		uniform mat4 projectionMatrix;

		attribute vec3 position;
		attribute vec2 uv;

		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}`,fragmentShader:`
	
		precision highp float;

		uniform sampler2D tDiffuse;

		#include <tonemapping_pars_fragment>
		#include <colorspace_pars_fragment>

		varying vec2 vUv;

		void main() {

			gl_FragColor = texture2D( tDiffuse, vUv );

			// tone mapping

			#ifdef LINEAR_TONE_MAPPING

				gl_FragColor.rgb = LinearToneMapping( gl_FragColor.rgb );

			#elif defined( REINHARD_TONE_MAPPING )

				gl_FragColor.rgb = ReinhardToneMapping( gl_FragColor.rgb );

			#elif defined( CINEON_TONE_MAPPING )

				gl_FragColor.rgb = CineonToneMapping( gl_FragColor.rgb );

			#elif defined( ACES_FILMIC_TONE_MAPPING )

				gl_FragColor.rgb = ACESFilmicToneMapping( gl_FragColor.rgb );

			#elif defined( AGX_TONE_MAPPING )

				gl_FragColor.rgb = AgXToneMapping( gl_FragColor.rgb );

			#elif defined( NEUTRAL_TONE_MAPPING )

				gl_FragColor.rgb = NeutralToneMapping( gl_FragColor.rgb );

			#endif

			// color space

			#ifdef SRGB_TRANSFER

				gl_FragColor = sRGBTransferOETF( gl_FragColor );

			#endif

		}`};class Cx extends ws{constructor(){super();const t=Rx;this.uniforms=Js.clone(t.uniforms),this.material=new Lv({name:t.name,uniforms:this.uniforms,vertexShader:t.vertexShader,fragmentShader:t.fragmentShader}),this.fsQuad=new Cl(this.material),this._outputColorSpace=null,this._toneMapping=null}render(t,e,n){this.uniforms.tDiffuse.value=n.texture,this.uniforms.toneMappingExposure.value=t.toneMappingExposure,(this._outputColorSpace!==t.outputColorSpace||this._toneMapping!==t.toneMapping)&&(this._outputColorSpace=t.outputColorSpace,this._toneMapping=t.toneMapping,this.material.defines={},Ht.getTransfer(this._outputColorSpace)===se&&(this.material.defines.SRGB_TRANSFER=""),this._toneMapping===Ih?this.material.defines.LINEAR_TONE_MAPPING="":this._toneMapping===Dh?this.material.defines.REINHARD_TONE_MAPPING="":this._toneMapping===Nh?this.material.defines.CINEON_TONE_MAPPING="":this._toneMapping===nl?this.material.defines.ACES_FILMIC_TONE_MAPPING="":this._toneMapping===Uh?this.material.defines.AGX_TONE_MAPPING="":this._toneMapping===Fh&&(this.material.defines.NEUTRAL_TONE_MAPPING=""),this.material.needsUpdate=!0),this.renderToScreen===!0?(t.setRenderTarget(null),this.fsQuad.render(t)):(t.setRenderTarget(e),this.clear&&t.clear(t.autoClearColor,t.autoClearDepth,t.autoClearStencil),this.fsQuad.render(t))}dispose(){this.material.dispose(),this.fsQuad.dispose()}}class Px extends ws{constructor(t,e,n=null,i=null,s=null){super(),this.scene=t,this.camera=e,this.overrideMaterial=n,this.clearColor=i,this.clearAlpha=s,this.clear=!0,this.clearDepth=!1,this.needsSwap=!1,this._oldClearColor=new dt}render(t,e,n){const i=t.autoClear;t.autoClear=!1;let s,a;this.overrideMaterial!==null&&(a=this.scene.overrideMaterial,this.scene.overrideMaterial=this.overrideMaterial),this.clearColor!==null&&(t.getClearColor(this._oldClearColor),t.setClearColor(this.clearColor,t.getClearAlpha())),this.clearAlpha!==null&&(s=t.getClearAlpha(),t.setClearAlpha(this.clearAlpha)),this.clearDepth==!0&&t.clearDepth(),t.setRenderTarget(this.renderToScreen?null:n),this.clear===!0&&t.clear(t.autoClearColor,t.autoClearDepth,t.autoClearStencil),t.render(this.scene,this.camera),this.clearColor!==null&&t.setClearColor(this._oldClearColor),this.clearAlpha!==null&&t.setClearAlpha(s),this.overrideMaterial!==null&&(this.scene.overrideMaterial=a),t.autoClear=i}}const Lx={uniforms:{tDiffuse:{value:null},luminosityThreshold:{value:1},smoothWidth:{value:1},defaultColor:{value:new dt(0)},defaultOpacity:{value:0}},vertexShader:`

		varying vec2 vUv;

		void main() {

			vUv = uv;

			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}`,fragmentShader:`

		uniform sampler2D tDiffuse;
		uniform vec3 defaultColor;
		uniform float defaultOpacity;
		uniform float luminosityThreshold;
		uniform float smoothWidth;

		varying vec2 vUv;

		void main() {

			vec4 texel = texture2D( tDiffuse, vUv );

			float v = luminance( texel.xyz );

			vec4 outputColor = vec4( defaultColor.rgb, defaultOpacity );

			float alpha = smoothstep( luminosityThreshold, luminosityThreshold + smoothWidth, v );

			gl_FragColor = mix( outputColor, texel, alpha );

		}`};class vs extends ws{constructor(t,e,n,i){super(),this.strength=e!==void 0?e:1,this.radius=n,this.threshold=i,this.resolution=t!==void 0?new nt(t.x,t.y):new nt(256,256),this.clearColor=new dt(0,0,0),this.renderTargetsHorizontal=[],this.renderTargetsVertical=[],this.nMips=5;let s=Math.round(this.resolution.x/2),a=Math.round(this.resolution.y/2);this.renderTargetBright=new fn(s,a,{type:Pn}),this.renderTargetBright.texture.name="UnrealBloomPass.bright",this.renderTargetBright.texture.generateMipmaps=!1;for(let u=0;u<this.nMips;u++){const d=new fn(s,a,{type:Pn});d.texture.name="UnrealBloomPass.h"+u,d.texture.generateMipmaps=!1,this.renderTargetsHorizontal.push(d);const f=new fn(s,a,{type:Pn});f.texture.name="UnrealBloomPass.v"+u,f.texture.generateMipmaps=!1,this.renderTargetsVertical.push(f),s=Math.round(s/2),a=Math.round(a/2)}const o=Lx;this.highPassUniforms=Js.clone(o.uniforms),this.highPassUniforms.luminosityThreshold.value=i,this.highPassUniforms.smoothWidth.value=.01,this.materialHighPassFilter=new Te({uniforms:this.highPassUniforms,vertexShader:o.vertexShader,fragmentShader:o.fragmentShader}),this.separableBlurMaterials=[];const l=[3,5,7,9,11];s=Math.round(this.resolution.x/2),a=Math.round(this.resolution.y/2);for(let u=0;u<this.nMips;u++)this.separableBlurMaterials.push(this.getSeperableBlurMaterial(l[u])),this.separableBlurMaterials[u].uniforms.invSize.value=new nt(1/s,1/a),s=Math.round(s/2),a=Math.round(a/2);this.compositeMaterial=this.getCompositeMaterial(this.nMips),this.compositeMaterial.uniforms.blurTexture1.value=this.renderTargetsVertical[0].texture,this.compositeMaterial.uniforms.blurTexture2.value=this.renderTargetsVertical[1].texture,this.compositeMaterial.uniforms.blurTexture3.value=this.renderTargetsVertical[2].texture,this.compositeMaterial.uniforms.blurTexture4.value=this.renderTargetsVertical[3].texture,this.compositeMaterial.uniforms.blurTexture5.value=this.renderTargetsVertical[4].texture,this.compositeMaterial.uniforms.bloomStrength.value=e,this.compositeMaterial.uniforms.bloomRadius.value=.1;const c=[1,.8,.6,.4,.2];this.compositeMaterial.uniforms.bloomFactors.value=c,this.bloomTintColors=[new P(1,1,1),new P(1,1,1),new P(1,1,1),new P(1,1,1),new P(1,1,1)],this.compositeMaterial.uniforms.bloomTintColors.value=this.bloomTintColors;const h=Vu;this.copyUniforms=Js.clone(h.uniforms),this.blendMaterial=new Te({uniforms:this.copyUniforms,vertexShader:h.vertexShader,fragmentShader:h.fragmentShader,blending:dn,depthTest:!1,depthWrite:!1,transparent:!0}),this.enabled=!0,this.needsSwap=!1,this._oldClearColor=new dt,this.oldClearAlpha=1,this.basic=new ne,this.fsQuad=new Cl(null)}dispose(){for(let t=0;t<this.renderTargetsHorizontal.length;t++)this.renderTargetsHorizontal[t].dispose();for(let t=0;t<this.renderTargetsVertical.length;t++)this.renderTargetsVertical[t].dispose();this.renderTargetBright.dispose();for(let t=0;t<this.separableBlurMaterials.length;t++)this.separableBlurMaterials[t].dispose();this.compositeMaterial.dispose(),this.blendMaterial.dispose(),this.basic.dispose(),this.fsQuad.dispose()}setSize(t,e){let n=Math.round(t/2),i=Math.round(e/2);this.renderTargetBright.setSize(n,i);for(let s=0;s<this.nMips;s++)this.renderTargetsHorizontal[s].setSize(n,i),this.renderTargetsVertical[s].setSize(n,i),this.separableBlurMaterials[s].uniforms.invSize.value=new nt(1/n,1/i),n=Math.round(n/2),i=Math.round(i/2)}render(t,e,n,i,s){t.getClearColor(this._oldClearColor),this.oldClearAlpha=t.getClearAlpha();const a=t.autoClear;t.autoClear=!1,t.setClearColor(this.clearColor,0),s&&t.state.buffers.stencil.setTest(!1),this.renderToScreen&&(this.fsQuad.material=this.basic,this.basic.map=n.texture,t.setRenderTarget(null),t.clear(),this.fsQuad.render(t)),this.highPassUniforms.tDiffuse.value=n.texture,this.highPassUniforms.luminosityThreshold.value=this.threshold,this.fsQuad.material=this.materialHighPassFilter,t.setRenderTarget(this.renderTargetBright),t.clear(),this.fsQuad.render(t);let o=this.renderTargetBright;for(let l=0;l<this.nMips;l++)this.fsQuad.material=this.separableBlurMaterials[l],this.separableBlurMaterials[l].uniforms.colorTexture.value=o.texture,this.separableBlurMaterials[l].uniforms.direction.value=vs.BlurDirectionX,t.setRenderTarget(this.renderTargetsHorizontal[l]),t.clear(),this.fsQuad.render(t),this.separableBlurMaterials[l].uniforms.colorTexture.value=this.renderTargetsHorizontal[l].texture,this.separableBlurMaterials[l].uniforms.direction.value=vs.BlurDirectionY,t.setRenderTarget(this.renderTargetsVertical[l]),t.clear(),this.fsQuad.render(t),o=this.renderTargetsVertical[l];this.fsQuad.material=this.compositeMaterial,this.compositeMaterial.uniforms.bloomStrength.value=this.strength,this.compositeMaterial.uniforms.bloomRadius.value=this.radius,this.compositeMaterial.uniforms.bloomTintColors.value=this.bloomTintColors,t.setRenderTarget(this.renderTargetsHorizontal[0]),t.clear(),this.fsQuad.render(t),this.fsQuad.material=this.blendMaterial,this.copyUniforms.tDiffuse.value=this.renderTargetsHorizontal[0].texture,s&&t.state.buffers.stencil.setTest(!0),this.renderToScreen?(t.setRenderTarget(null),this.fsQuad.render(t)):(t.setRenderTarget(n),this.fsQuad.render(t)),t.setClearColor(this._oldClearColor,this.oldClearAlpha),t.autoClear=a}getSeperableBlurMaterial(t){const e=[];for(let n=0;n<t;n++)e.push(.39894*Math.exp(-.5*n*n/(t*t))/t);return new Te({defines:{KERNEL_RADIUS:t},uniforms:{colorTexture:{value:null},invSize:{value:new nt(.5,.5)},direction:{value:new nt(.5,.5)},gaussianCoefficients:{value:e}},vertexShader:`varying vec2 vUv;
				void main() {
					vUv = uv;
					gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
				}`,fragmentShader:`#include <common>
				varying vec2 vUv;
				uniform sampler2D colorTexture;
				uniform vec2 invSize;
				uniform vec2 direction;
				uniform float gaussianCoefficients[KERNEL_RADIUS];

				void main() {
					float weightSum = gaussianCoefficients[0];
					vec3 diffuseSum = texture2D( colorTexture, vUv ).rgb * weightSum;
					for( int i = 1; i < KERNEL_RADIUS; i ++ ) {
						float x = float(i);
						float w = gaussianCoefficients[i];
						vec2 uvOffset = direction * invSize * x;
						vec3 sample1 = texture2D( colorTexture, vUv + uvOffset ).rgb;
						vec3 sample2 = texture2D( colorTexture, vUv - uvOffset ).rgb;
						diffuseSum += (sample1 + sample2) * w;
						weightSum += 2.0 * w;
					}
					gl_FragColor = vec4(diffuseSum/weightSum, 1.0);
				}`})}getCompositeMaterial(t){return new Te({defines:{NUM_MIPS:t},uniforms:{blurTexture1:{value:null},blurTexture2:{value:null},blurTexture3:{value:null},blurTexture4:{value:null},blurTexture5:{value:null},bloomStrength:{value:1},bloomFactors:{value:null},bloomTintColors:{value:null},bloomRadius:{value:0}},vertexShader:`varying vec2 vUv;
				void main() {
					vUv = uv;
					gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
				}`,fragmentShader:`varying vec2 vUv;
				uniform sampler2D blurTexture1;
				uniform sampler2D blurTexture2;
				uniform sampler2D blurTexture3;
				uniform sampler2D blurTexture4;
				uniform sampler2D blurTexture5;
				uniform float bloomStrength;
				uniform float bloomRadius;
				uniform float bloomFactors[NUM_MIPS];
				uniform vec3 bloomTintColors[NUM_MIPS];

				float lerpBloomFactor(const in float factor) {
					float mirrorFactor = 1.2 - factor;
					return mix(factor, mirrorFactor, bloomRadius);
				}

				void main() {
					gl_FragColor = bloomStrength * ( lerpBloomFactor(bloomFactors[0]) * vec4(bloomTintColors[0], 1.0) * texture2D(blurTexture1, vUv) +
						lerpBloomFactor(bloomFactors[1]) * vec4(bloomTintColors[1], 1.0) * texture2D(blurTexture2, vUv) +
						lerpBloomFactor(bloomFactors[2]) * vec4(bloomTintColors[2], 1.0) * texture2D(blurTexture3, vUv) +
						lerpBloomFactor(bloomFactors[3]) * vec4(bloomTintColors[3], 1.0) * texture2D(blurTexture4, vUv) +
						lerpBloomFactor(bloomFactors[4]) * vec4(bloomTintColors[4], 1.0) * texture2D(blurTexture5, vUv) );
				}`})}}vs.BlurDirectionX=new nt(1,0);vs.BlurDirectionY=new nt(0,1);class Mh{constructor(t,e){this.canvas=t,this.scene=new cv,this.width=1,this.height=1,this.pixelRatio=1,this.contextLost=!1,this.composer=null,this.renderPass=null,this.bloomOn=!1,this.gl=new lv({canvas:t,antialias:e,alpha:!1,powerPreference:"high-performance",stencil:!1}),this.gl.outputColorSpace=be,this.gl.toneMapping=nl,this.gl.toneMappingExposure=1.15,this.gl.info.autoReset=!1,t.addEventListener("webglcontextlost",n=>{n.preventDefault(),this.contextLost=!0}),t.addEventListener("webglcontextrestored",()=>{this.contextLost=!1})}static supported(){try{return!!document.createElement("canvas").getContext("webgl2")}catch{return!1}}resize(t,e,n){const i=Math.max(1,Math.floor(t)),s=Math.max(1,Math.floor(e));return i===this.width&&s===this.height&&Math.abs(n-this.pixelRatio)<.01?!1:(this.width=i,this.height=s,this.pixelRatio=n,this.gl.setPixelRatio(n),this.gl.setSize(i,s,!1),this.composer?.setPixelRatio(n),this.composer?.setSize(i,s),!0)}setBloom(t){if(this.bloomOn=t&&this.gl.capabilities.isWebGL2&&!!this.gl.extensions.get("EXT_color_buffer_float"),!this.bloomOn){this.composer?.dispose(),this.composer=null;return}if(this.composer)return;const e=new fn(this.width,this.height,{type:Pn,samples:2});this.composer=new Ax(this.gl,e),this.renderPass=new Px(this.scene,new ze),this.composer.addPass(this.renderPass),this.composer.addPass(new vs(new nt(this.width/2,this.height/2),.42,.55,.82)),this.composer.addPass(new Cx),this.composer.setPixelRatio(this.pixelRatio),this.composer.setSize(this.width,this.height)}render(t){this.contextLost||(this.composer&&this.renderPass?(this.renderPass.camera=t,this.composer.render()):this.gl.render(this.scene,t))}stats(){const t=this.gl.info,e={drawCalls:t.render.calls,triangles:t.render.triangles,geometries:t.memory.geometries,textures:t.memory.textures,pixelRatio:this.pixelRatio,width:this.width,height:this.height};return t.reset(),e}}const bh=14;class Ix{constructor(t,e){this.floaters=[],this.floaterCursor=0,this.last={},this.bannerTimer=0,this.introEl=D("div.intro"),this.warnEl=D("div.warn-band"),this.introTimer=0,this.warnTimer=0,this.levelEl=D("div.hud-level"),this.progressFill=D("div.hud-progress-fill"),this.scoreEl=D("div.hud-score",null,"0"),this.armyEl=D("span.hud-army-num",null,"0"),this.armyWrap=D("div.hud-army",null,D("span.hud-army-icon"),this.armyEl),this.hpFill=D("div.bar-fill.hp"),this.hpNum=D("span.hp-num",null,"100"),this.bossName=D("div.boss-name"),this.bossFill=D("div.bar-fill.boss"),this.bossShield=D("div.bar-fill.shield"),this.bossWrap=D("div.boss-bar.hidden",null,this.bossName,D("div.bar",null,this.bossFill,this.bossShield)),this.abilityRing=D("div.ability-ring"),this.abilityBtn=D("button.ability",{type:"button",ariaLabel:"Overdrive"},this.abilityRing,Ue("bolt","ability-icon"),D("span.ability-label",null,"OVERDRIVE")),this.abilityBtn.addEventListener("pointerdown",s=>{s.stopPropagation(),e()}),this.banner=D("div.banner"),this.hint=D("div.hint.hidden",null,D("span.hint-hand"),"Drag to steer your cannon"),this.vignette=D("div.vignette");const n=D("button.icon-btn.pause",{type:"button",ariaLabel:"Pause"},D("span"),D("span"));n.addEventListener("pointerdown",s=>{s.stopPropagation(),t()});const i=D("div.floaters");for(let s=0;s<bh;s++){const a=D("div.floater");this.floaters.push(a),i.append(a)}this.el=D("div.hud.hidden",null,this.vignette,D("div.hud-top",null,n,D("div.hud-mid",null,this.levelEl,D("div.hud-progress",null,this.progressFill,Ue("skull","hud-progress-boss"))),D("div.hud-score-wrap",null,D("div.hud-score-label",null,"SCORE"),this.scoreEl)),this.bossWrap,this.armyWrap,i,this.banner,this.introEl,this.warnEl,this.hint,D("div.hud-bottom",null,D("div.hp-wrap",null,D("span.hp-label",null,"CANNON ",this.hpNum),D("div.bar",null,this.hpFill)),this.abilityBtn))}show(t){this.el.classList.toggle("hidden",!t)}reset(){this.last={},this.banner.classList.remove("show"),this.introEl.classList.remove("show"),this.warnEl.classList.remove("show"),this.vignette.classList.remove("low"),this.hint.classList.add("hidden");for(const t of this.floaters)t.classList.remove("go")}showHint(t){this.hint.classList.toggle("hidden",!t)}update(t){const e=this.last;e.title!==t.title&&(this.levelEl.textContent=t.title),(e.progress===void 0||Math.abs(e.progress-t.progress)>.004)&&(this.progressFill.style.transform=`scaleX(${t.progress.toFixed(3)})`,e.progress=t.progress),e.army!==t.army&&(this.armyEl.textContent=Re(t.army),e.army!==void 0&&t.army>e.army&&(this.armyWrap.classList.remove("bump"),this.armyWrap.offsetWidth,this.armyWrap.classList.add("bump"))),e.atCap!==t.atCap&&this.armyWrap.classList.toggle("cap",t.atCap),e.score!==t.score&&(this.scoreEl.textContent=Re(t.score)),e.cannonHp!==t.cannonHp&&(this.hpFill.style.transform=`scaleX(${Math.max(0,t.cannonHp).toFixed(3)})`,this.hpFill.classList.toggle("low",t.cannonHp<.35),this.vignette.classList.toggle("low",t.cannonHp<.35&&t.cannonHp>0),this.hpNum.textContent=String(Math.ceil(Math.max(0,t.cannonHp)*100))),e.bossName!==t.bossName&&(this.bossWrap.classList.toggle("hidden",!t.bossName),this.bossName.textContent=t.bossName??""),e.bossHp!==t.bossHp&&(this.bossFill.style.transform=`scaleX(${Math.max(0,t.bossHp).toFixed(3)})`),e.bossShield!==t.bossShield&&(this.bossShield.style.transform=`scaleX(${Math.max(0,t.bossShield).toFixed(3)})`),e.abilityCooldown!==t.abilityCooldown&&(this.abilityRing.style.setProperty("--cd",String(Math.round(t.abilityCooldown*360))),this.abilityBtn.classList.toggle("ready",t.abilityCooldown<=0)),e.abilityActive!==t.abilityActive&&this.abilityBtn.classList.toggle("active",t.abilityActive);const n=e.progress;Object.assign(e,t),e.progress=n}float(t,e,n,i,s=!1){const a=this.floaters[this.floaterCursor];this.floaterCursor=(this.floaterCursor+1)%bh,a.textContent=t,a.style.color=i,a.style.left=`${e.toFixed(0)}px`,a.style.top=`${n.toFixed(0)}px`,a.classList.toggle("big",s),a.classList.remove("go"),a.offsetWidth,a.classList.add("go")}announce(t,e="info",n=1800){this.banner.textContent=t,this.banner.className=`banner show ${e}`,window.clearTimeout(this.bannerTimer),this.bannerTimer=window.setTimeout(()=>this.banner.classList.remove("show"),n)}intro(t,e,n,i,s){this.introEl.className=`intro show w-${n}`,this.introEl.replaceChildren(D("div.intro-kicker",null,i.toUpperCase()),D("div.intro-level",null,t),D("div.intro-name",null,e),D("div.intro-boss",null,Ue("skull"),`Boss: ${s}`)),window.clearTimeout(this.introTimer),this.introTimer=window.setTimeout(()=>this.introEl.classList.remove("show"),1900)}bossWarning(t){this.warnEl.replaceChildren(D("div.warn-strip"),D("div.warn-text",null,Ue("warn"),D("span",null,"WARNING"),D("b",null,t.toUpperCase())),D("div.warn-strip")),this.warnEl.classList.add("show"),window.clearTimeout(this.warnTimer),this.warnTimer=window.setTimeout(()=>this.warnEl.classList.remove("show"),2400)}damageFlash(){this.vignette.classList.remove("hit"),this.vignette.offsetWidth,this.vignette.classList.add("hit")}}class Dx{constructor(t){this.body=D("div.board"),this.el=D("div.screen.panel-screen",null,D("div.panel",null,D("div.panel-head",null,D("h2.title",null,"Leaderboard"),ar("✕","close",t)),this.body))}loading(){this.body.replaceChildren(D("div.note",null,"Loading…"))}show(t,e,n,i=!1){const s=D("div.board-me",null,D("span",null,"Your career score"),D("b",null,Re(e)));if(i||!t){this.body.replaceChildren(s,D("div.note",null,n));return}const a=t.map(o=>D(`div.board-row${o.isPlayer?".me":""}${o.rank<=3?`.top.r${o.rank}`:""}`,null,D("span.rank",null,`#${o.rank}`),D("span.name",null,o.name),D("b",null,Re(o.score))));Ou(this.body,s,...a,n?D("div.note",null,n):null)}}class Nx{constructor(t,e){this.onPick=t,this.grid=D("div.level-grid"),this.el=D("div.screen.panel-screen",null,D("div.panel",null,D("div.panel-head",null,D("h2.title",null,"Select Level"),ar("✕","close",e)),this.grid))}refresh(t){this.grid.replaceChildren();for(const e of qo)this.grid.append(D("div.level-head",null,gs[e].split(" ")[0].toUpperCase()));for(let e=1;e<=en;e++){const n=Ys(e),i=e>t.unlocked,s=t.best[e],a=D(`button.level-tile.w-${n.world}${i?".locked":""}${e===t.unlocked?".current":""}`,{type:"button",disabled:i,title:`${n.name} — ${gs[n.world]}`},i?Ue("lock","level-lock"):D("span.level-num",null,String(e)),D("span.level-boss",null,n.boss.kind==="titan"?"TITAN":n.boss.kind==="inferno"?"INFERNO":"VOID"),ku(s?.stars??0));i||(a.onclick=()=>this.onPick(e)),this.grid.append(a)}}}const Gu="hash_rush_save_v1";function Ux(){return{version:1,upgrades:W_(),unlocked:1,best:{},settings:{music:!0,sfx:!0,haptics:!0,quality:"auto"},pending:[],endless:{score:0,stage:0},skins:N_()}}const ci=(r,t,e,n)=>typeof r=="number"&&Number.isFinite(r)?Math.min(n,Math.max(e,Math.floor(r))):t;function Fx(r){const t=Ux();let e;try{e=JSON.parse(r?.getItem(Gu)??"null")}catch{return t}if(!e||typeof e!="object")return t;const n=e;t.unlocked=ci(n.unlocked,1,1,en);const i=n.upgrades??{};for(const c of Bu)t.upgrades[c]=ci(i[c],0,0,_i[c].maxLevel);const s=n.best??{};for(const c of Object.keys(s)){const h=Number(c);!Number.isInteger(h)||h<1||h>en||(t.best[h]={score:ci(s[c]?.score,0,0,1e7),stars:ci(s[c]?.stars,0,0,3)})}const a=n.settings??{};if(t.settings.music=a.music!==!1,t.settings.sfx=a.sfx!==!1,t.settings.haptics=a.haptics!==!1,(a.quality==="low"||a.quality==="medium"||a.quality==="high")&&(t.settings.quality=a.quality),Array.isArray(n.pending))for(const c of n.pending.slice(-10))c&&typeof c.runId=="string"&&t.pending.push({runId:c.runId,score:ci(c.score,0,0,1e7),level:ci(c.level,1,1,en)});const o=n.endless??{};t.endless={score:ci(o.score,0,0,1e8),stage:ci(o.stage,0,0,9999)};const l=n.skins??{};for(const c of["army","cannon"]){const h=Array.isArray(l.owned?.[c])?l.owned[c]:[];for(const d of h)typeof d=="string"&&nr.some(f=>f.id===d)&&!t.skins.owned[c].includes(d)&&t.skins.owned[c].push(d);const u=l[c];typeof u=="string"&&t.skins.owned[c].includes(u)&&(t.skins[c]=u)}return t}function Ox(r,t){try{return r?.setItem(Gu,JSON.stringify(t)),r!=null}catch{return!1}}function kx(r,t,e){const n=r.best[t.id];let i=null;e.status==="won"&&t.id>=r.unlocked&&t.id<en&&(r.unlocked=t.id+1,i=r.unlocked);const s=e.status==="won"&&(!n||e.score>n.score);return e.status==="won"&&(r.best[t.id]={score:Math.max(n?.score??0,e.score),stars:Math.max(n?.stars??0,e.stars)}),{newBest:s,unlockedLevel:i}}function Bx(r,t){const e=r.upgrades[t];return e>=_i[t].maxLevel?!1:(r.upgrades[t]=e+1,!0)}function Wu(r,t,e){return r.skins.owned[t].includes(ir(e).id)}function zx(r,t,e){return Wu(r,t,e)?(r.skins[t]=ir(e).id,!0):!1}function Hx(r,t,e){const n=ir(e);r.skins.owned[t].includes(n.id)||r.skins.owned[t].push(n.id),r.skins[t]=n.id}function Vx(r,t){let e=!1;for(const n of["army","cannon"])for(const i of t[n]??[])nr.some(s=>s.id===i)&&!r.skins.owned[n].includes(i)&&(r.skins.owned[n].push(i),e=!0);return e}function Sh(r,t,e){const n=t>r.endless.score;return n&&(r.endless.score=Math.round(t)),e>r.endless.stage&&(r.endless.stage=e),n}function Yr(r){let t=0;for(const e of Object.keys(r.best))t+=r.best[Number(e)].score;return t+Math.min(B_,r.endless.score)}class Gx{constructor(t){this.balance=D("span.credit-num"),this.wallet=D("div.credits",null,D("span.credit-icon"),this.balance),this.playSub=D("span.btn-sub"),this.stats=D("div.menu-stats"),this.card=D("div.next-card"),this.endlessSub=D("span.btn-sub");const e=D("button.btn.primary.huge",{type:"button",onclick:t.play},D("span.play-row",null,Ue("play"),"PLAY"),this.playSub),n=(i,s,a)=>D("button.dock-tab",{type:"button",onclick:a},Ue(i),D("span",null,s));this.endlessBtn=D("button.btn.endless",{type:"button",onclick:t.endless},D("span.play-row",null,Ue("loop"),"ENDLESS"),this.endlessSub),this.el=D("div.screen.menu",null,D("div.menu-top",null,this.wallet,D("span.menu-top-gap"),D("button.icon-btn.gear",{type:"button",ariaLabel:"Settings",onclick:t.settings},Ue("gear"))),D("div.logo",null,D("div.logo-hash",null,"HASH"),D("div.logo-rush",null,"RUSH")),D("div.menu-tag",null,"Fire. Multiply. Overwhelm."),this.stats,D("div.menu-spacer"),this.card,e,this.endlessBtn,D("div.dock",null,n("grid","LEVELS",t.levels),n("up","UPGRADES",t.upgrades),n("brush","SKINS",t.skins),n("trophy","RANKS",t.leaderboard)))}refresh(t,e){const n=Ys(t.unlocked),i=e?.balance??null;this.wallet.hidden=i==null,this.balance.textContent=i==null?"":Re(i),this.playSub.textContent=`Level ${n.id} · ${gs[n.world]}`;const s=t.unlocked>Ko;this.endlessBtn.disabled=!s,this.endlessBtn.classList.toggle("locked",!s),this.endlessSub.textContent=s?t.endless.stage>0?`Best: stage ${t.endless.stage} · ${Re(t.endless.score)} pts`:"How far can you go?":`Clear level ${Ko} to unlock`;let a=0,o=0;for(const h of Object.keys(t.best))a+=t.best[Number(h)].stars,o++;const l=(h,u,d)=>D("div.menu-stat",null,Ue(h),D("b",null,u),D("span",null,d));this.stats.replaceChildren(l("star",`${a}/${en*3}`,"STARS"),l("grid",`${o}/${en}`,"CLEARED"),l("trophy",Re(Yr(t)),"SCORE"));const c=D("i");c.style.width=`${o/en*100}%`,this.card.className=`next-card w-${n.world}`,this.card.replaceChildren(D("div.next-main",null,D("div.next-kicker",null,`UP NEXT · LEVEL ${n.id}`),D("div.next-name",null,n.name),D("div.next-progress",null,c)),D("div.next-boss",null,Ue("skull"),D("span",null,"BOSS"),D("b",null,ta[n.boss.kind].name)))}}class Wx{constructor(t){this.info=D("div.pause-info"),this.el=D("div.screen.panel-screen.dim",null,D("div.panel.narrow",null,D("h2.title",null,"Paused"),this.info,Cn("play","RESUME","primary",t.resume),Cn("restart","RESTART","ghost",t.restart),Cn("gear","SETTINGS","ghost",t.settings),Cn("exit","QUIT TO MENU","ghost danger",t.quit)))}refresh(t){const e=(n,i)=>D("div.stat",null,D("span",null,n),D("b",null,i));this.info.replaceChildren(D("div.pause-level",null,t.title),D("div.stats.three",null,e("Progress",`${Math.round(t.progress*100)}%`),e("Army",Re(t.army)),e("Score",Re(t.score))))}}const wh=["Tip: multiplier gates are worth more the bigger your army already is.","Tip: steer the cannon — your whole army follows it.","Tip: shoot barrels when enemies are standing next to them.","Tip: step out of the red circles to dodge boss shots.","Tip: upgrades make every level easier — and retries are free.","Tip: save Overdrive for the boss or a big wave."];class Xx{constructor(t){this.actions=t,this.body=D("div.panel.narrow.result"),this.raf=0,this.lastShown=-1,this.el=D("div.screen.panel-screen.dim",null,this.body)}countUp(t,e){if(cancelAnimationFrame(this.raf),this.lastShown===e){t.textContent=Re(e);return}this.lastShown=e;const n=performance.now(),i=s=>{const a=Math.min(1,(s-n)/900);t.textContent=Re(e*(1-Math.pow(1-a,3))),a<1&&(this.raf=requestAnimationFrame(i))};this.raf=requestAnimationFrame(i)}show(t,e,n,i,s=1,a=0){const o=t.status==="won",l=(h,u)=>D("div.stat",null,D("span",null,h),D("b",null,u));this.body.className=`panel narrow result ${o?"won":"lost"}`;const c=D("div.result-score",null,"0");this.countUp(c,t.score),Ou(this.body,D("div.result-title",null,a?"RUN OVER":o?"VICTORY":"DEFEATED"),a?D("div.result-sub.big",null,`Endless · reached stage ${a}`):o?ku(t.stars):D("div.result-sub",null,`Your cannon was destroyed · ${Math.round(s*100)}% of the way`),c,e.newBest?D("div.badge",null,"NEW BEST"):null,D("div.stats",null,l("Enemies destroyed",Re(t.enemiesKilled)),l("Peak army",Re(t.peakArmy)),l("Units lost",Re(t.unitsLost)),l("Time",`${Math.floor(t.time/60)}:${String(Math.floor(t.time%60)).padStart(2,"0")}`)),e.unlockedLevel?D("div.result-sub.good",null,`Level ${e.unlockedLevel} unlocked`):null,o?null:D("div.tip",null,wh[Math.floor(t.time)%wh.length]),o&&n?Cn("next","NEXT LEVEL","primary",this.actions.next):Cn("restart",o?"PLAY AGAIN":"TRY AGAIN","primary",this.actions.retry),D("div.menu-row",null,o&&n?Cn("restart","REPLAY","ghost tab",this.actions.retry):null,Cn("up","UPGRADES","ghost tab",this.actions.upgrades),Cn("grid","MENU","ghost tab",this.actions.menu)),i?D("div.note",null,i):null)}}class qx{constructor(t,e,n){this.onChange=t,this.info=n,this.body=D("div.settings"),this.el=D("div.screen.panel-screen.dim",null,D("div.panel.narrow",null,D("div.panel-head",null,D("h2.title",null,"Settings"),ar("✕","close",e)),this.body))}refresh(t){const e=(s,a)=>{const o=D(`button.switch${t[a]?".on":""}`,{type:"button",role:"switch",ariaChecked:String(t[a])},D("i"));return o.onclick=()=>{t[a]=!t[a],this.onChange(t),this.refresh(t)},D("div.setting",null,D("span",null,s),o)},n=["auto","low","medium","high"],i=D("div.segmented");for(const s of n){const a=D(`button${t.quality===s?".on":""}`,{type:"button"},s.toUpperCase());a.onclick=()=>{t.quality=s,this.onChange(t),this.refresh(t)},i.append(a)}this.body.replaceChildren(e("Music","music"),e("Sound effects","sfx"),e("Vibration","haptics"),D("div.setting.col",null,D("span",null,"Graphics"),i),D("div.note",null,this.info()))}}const Yx={fireRate:"fire",startArmy:"bot",unitDamage:"sword",unitHealth:"shield",cannonPower:"burst",abilityCooldown:"bolt"};class Kx{constructor(t,e){this.onBuy=t,this.list=D("div.upgrade-list"),this.balance=D("span.credit-num"),this.wallet=D("div.credits",null,D("span.credit-icon"),this.balance),this.justBought=null,this.el=D("div.screen.panel-screen",null,D("div.panel",null,D("div.panel-head",null,D("h2.title",null,"Upgrades"),this.wallet,ar("✕","close",e)),this.list))}refresh(t,e){const n=e?.balance??null;this.wallet.hidden=n==null,this.balance.textContent=n==null?"":Re(n),this.list.replaceChildren(),this.list.classList.remove("busy");for(const i of Bu){const s=_i[i],a=t.upgrades[i],o=a>=s.maxLevel,l=e?.upgrades[i]?.[a]??null,c=l==null||n!=null&&n<l,h=D(`button.btn.buy${o?".maxed":c?".poor":".can"}`,{type:"button",onclick:()=>{this.justBought=i,o||(h.classList.add("loading"),this.list.classList.add("busy")),this.onBuy(i)}},o?"MAX":l==null?"—":D("span",null,D("span.credit-icon"),Re(l)));h.disabled=!o&&l==null;const u=D("div.pips");for(let d=0;d<s.maxLevel;d++)u.append(D(`i${d<a?".on":""}`));this.list.append(D(`div.upgrade${this.justBought===i?".bought":""}`,null,D(`div.upgrade-icon.u-${i}`,null,Ue(Yx[i])),D("div.upgrade-info",null,D("div.upgrade-name",null,s.name,D("span.upgrade-lvl",null,`Lv ${a}`)),D("div.upgrade-desc",null,s.desc),D("div.upgrade-val",null,s.format(s.value(a)),o?null:D("span.arrow",null,` → ${s.format(s.value(a+1))}`)),u),h))}this.justBought=null}}class $x extends Ss{constructor(t){super(t),this.dracoLoader=null,this.ktx2Loader=null,this.meshoptDecoder=null,this.pluginCallbacks=[],this.register(function(e){return new ty(e)}),this.register(function(e){return new ey(e)}),this.register(function(e){return new hy(e)}),this.register(function(e){return new uy(e)}),this.register(function(e){return new dy(e)}),this.register(function(e){return new iy(e)}),this.register(function(e){return new sy(e)}),this.register(function(e){return new ry(e)}),this.register(function(e){return new ay(e)}),this.register(function(e){return new Qx(e)}),this.register(function(e){return new oy(e)}),this.register(function(e){return new ny(e)}),this.register(function(e){return new cy(e)}),this.register(function(e){return new ly(e)}),this.register(function(e){return new Zx(e)}),this.register(function(e){return new fy(e)}),this.register(function(e){return new py(e)})}load(t,e,n,i){const s=this;let a;if(this.resourcePath!=="")a=this.resourcePath;else if(this.path!==""){const c=qs.extractUrlBase(t);a=qs.resolveURL(c,this.path)}else a=qs.extractUrlBase(t);this.manager.itemStart(t);const o=function(c){i?i(c):console.error(c),s.manager.itemError(t),s.manager.itemEnd(t)},l=new Su(this.manager);l.setPath(this.path),l.setResponseType("arraybuffer"),l.setRequestHeader(this.requestHeader),l.setWithCredentials(this.withCredentials),l.load(t,function(c){try{s.parse(c,a,function(h){e(h),s.manager.itemEnd(t)},o)}catch(h){o(h)}},n,o)}setDRACOLoader(t){return this.dracoLoader=t,this}setKTX2Loader(t){return this.ktx2Loader=t,this}setMeshoptDecoder(t){return this.meshoptDecoder=t,this}register(t){return this.pluginCallbacks.indexOf(t)===-1&&this.pluginCallbacks.push(t),this}unregister(t){return this.pluginCallbacks.indexOf(t)!==-1&&this.pluginCallbacks.splice(this.pluginCallbacks.indexOf(t),1),this}parse(t,e,n,i){let s;const a={},o={},l=new TextDecoder;if(typeof t=="string")s=JSON.parse(t);else if(t instanceof ArrayBuffer)if(l.decode(new Uint8Array(t,0,4))===Xu){try{a[zt.KHR_BINARY_GLTF]=new my(t)}catch(u){i&&i(u);return}s=JSON.parse(a[zt.KHR_BINARY_GLTF].content)}else s=JSON.parse(l.decode(t));else s=t;if(s.asset===void 0||s.asset.version[0]<2){i&&i(new Error("THREE.GLTFLoader: Unsupported asset. glTF versions >=2.0 are supported."));return}const c=new Ry(s,{path:e||this.resourcePath||"",crossOrigin:this.crossOrigin,requestHeader:this.requestHeader,manager:this.manager,ktx2Loader:this.ktx2Loader,meshoptDecoder:this.meshoptDecoder});c.fileLoader.setRequestHeader(this.requestHeader);for(let h=0;h<this.pluginCallbacks.length;h++){const u=this.pluginCallbacks[h](c);u.name||console.error("THREE.GLTFLoader: Invalid plugin found: missing name"),o[u.name]=u,a[u.name]=!0}if(s.extensionsUsed)for(let h=0;h<s.extensionsUsed.length;++h){const u=s.extensionsUsed[h],d=s.extensionsRequired||[];switch(u){case zt.KHR_MATERIALS_UNLIT:a[u]=new Jx;break;case zt.KHR_DRACO_MESH_COMPRESSION:a[u]=new gy(s,this.dracoLoader);break;case zt.KHR_TEXTURE_TRANSFORM:a[u]=new vy;break;case zt.KHR_MESH_QUANTIZATION:a[u]=new _y;break;default:d.indexOf(u)>=0&&o[u]===void 0&&console.warn('THREE.GLTFLoader: Unknown extension "'+u+'".')}}c.setExtensions(a),c.setPlugins(o),c.parse(n,i)}parseAsync(t,e){const n=this;return new Promise(function(i,s){n.parse(t,e,i,s)})}}function jx(){let r={};return{get:function(t){return r[t]},add:function(t,e){r[t]=e},remove:function(t){delete r[t]},removeAll:function(){r={}}}}const zt={KHR_BINARY_GLTF:"KHR_binary_glTF",KHR_DRACO_MESH_COMPRESSION:"KHR_draco_mesh_compression",KHR_LIGHTS_PUNCTUAL:"KHR_lights_punctual",KHR_MATERIALS_CLEARCOAT:"KHR_materials_clearcoat",KHR_MATERIALS_DISPERSION:"KHR_materials_dispersion",KHR_MATERIALS_IOR:"KHR_materials_ior",KHR_MATERIALS_SHEEN:"KHR_materials_sheen",KHR_MATERIALS_SPECULAR:"KHR_materials_specular",KHR_MATERIALS_TRANSMISSION:"KHR_materials_transmission",KHR_MATERIALS_IRIDESCENCE:"KHR_materials_iridescence",KHR_MATERIALS_ANISOTROPY:"KHR_materials_anisotropy",KHR_MATERIALS_UNLIT:"KHR_materials_unlit",KHR_MATERIALS_VOLUME:"KHR_materials_volume",KHR_TEXTURE_BASISU:"KHR_texture_basisu",KHR_TEXTURE_TRANSFORM:"KHR_texture_transform",KHR_MESH_QUANTIZATION:"KHR_mesh_quantization",KHR_MATERIALS_EMISSIVE_STRENGTH:"KHR_materials_emissive_strength",EXT_MATERIALS_BUMP:"EXT_materials_bump",EXT_TEXTURE_WEBP:"EXT_texture_webp",EXT_TEXTURE_AVIF:"EXT_texture_avif",EXT_MESHOPT_COMPRESSION:"EXT_meshopt_compression",EXT_MESH_GPU_INSTANCING:"EXT_mesh_gpu_instancing"};class Zx{constructor(t){this.parser=t,this.name=zt.KHR_LIGHTS_PUNCTUAL,this.cache={refs:{},uses:{}}}_markDefs(){const t=this.parser,e=this.parser.json.nodes||[];for(let n=0,i=e.length;n<i;n++){const s=e[n];s.extensions&&s.extensions[this.name]&&s.extensions[this.name].light!==void 0&&t._addNodeRef(this.cache,s.extensions[this.name].light)}}_loadLight(t){const e=this.parser,n="light:"+t;let i=e.cache.get(n);if(i)return i;const s=e.json,l=((s.extensions&&s.extensions[this.name]||{}).lights||[])[t];let c;const h=new dt(16777215);l.color!==void 0&&h.setRGB(l.color[0],l.color[1],l.color[2],qe);const u=l.range!==void 0?l.range:0;switch(l.type){case"directional":c=new wu(h),c.target.position.set(0,0,-1),c.add(c.target);break;case"point":c=new jv(h),c.distance=u;break;case"spot":c=new Kv(h),c.distance=u,l.spot=l.spot||{},l.spot.innerConeAngle=l.spot.innerConeAngle!==void 0?l.spot.innerConeAngle:0,l.spot.outerConeAngle=l.spot.outerConeAngle!==void 0?l.spot.outerConeAngle:Math.PI/4,c.angle=l.spot.outerConeAngle,c.penumbra=1-l.spot.innerConeAngle/l.spot.outerConeAngle,c.target.position.set(0,0,-1),c.add(c.target);break;default:throw new Error("THREE.GLTFLoader: Unexpected light type: "+l.type)}return c.position.set(0,0,0),c.decay=2,Xn(c,l),l.intensity!==void 0&&(c.intensity=l.intensity),c.name=e.createUniqueName(l.name||"light_"+t),i=Promise.resolve(c),e.cache.add(n,i),i}getDependency(t,e){if(t==="light")return this._loadLight(e)}createNodeAttachment(t){const e=this,n=this.parser,s=n.json.nodes[t],o=(s.extensions&&s.extensions[this.name]||{}).light;return o===void 0?null:this._loadLight(o).then(function(l){return n._getNodeRef(e.cache,o,l)})}}class Jx{constructor(){this.name=zt.KHR_MATERIALS_UNLIT}getMaterialType(){return ne}extendParams(t,e,n){const i=[];t.color=new dt(1,1,1),t.opacity=1;const s=e.pbrMetallicRoughness;if(s){if(Array.isArray(s.baseColorFactor)){const a=s.baseColorFactor;t.color.setRGB(a[0],a[1],a[2],qe),t.opacity=a[3]}s.baseColorTexture!==void 0&&i.push(n.assignTexture(t,"map",s.baseColorTexture,be))}return Promise.all(i)}}class Qx{constructor(t){this.parser=t,this.name=zt.KHR_MATERIALS_EMISSIVE_STRENGTH}extendMaterialParams(t,e){const i=this.parser.json.materials[t];if(!i.extensions||!i.extensions[this.name])return Promise.resolve();const s=i.extensions[this.name].emissiveStrength;return s!==void 0&&(e.emissiveIntensity=s),Promise.resolve()}}class ty{constructor(t){this.parser=t,this.name=zt.KHR_MATERIALS_CLEARCOAT}getMaterialType(t){const n=this.parser.json.materials[t];return!n.extensions||!n.extensions[this.name]?null:Dn}extendMaterialParams(t,e){const n=this.parser,i=n.json.materials[t];if(!i.extensions||!i.extensions[this.name])return Promise.resolve();const s=[],a=i.extensions[this.name];if(a.clearcoatFactor!==void 0&&(e.clearcoat=a.clearcoatFactor),a.clearcoatTexture!==void 0&&s.push(n.assignTexture(e,"clearcoatMap",a.clearcoatTexture)),a.clearcoatRoughnessFactor!==void 0&&(e.clearcoatRoughness=a.clearcoatRoughnessFactor),a.clearcoatRoughnessTexture!==void 0&&s.push(n.assignTexture(e,"clearcoatRoughnessMap",a.clearcoatRoughnessTexture)),a.clearcoatNormalTexture!==void 0&&(s.push(n.assignTexture(e,"clearcoatNormalMap",a.clearcoatNormalTexture)),a.clearcoatNormalTexture.scale!==void 0)){const o=a.clearcoatNormalTexture.scale;e.clearcoatNormalScale=new nt(o,o)}return Promise.all(s)}}class ey{constructor(t){this.parser=t,this.name=zt.KHR_MATERIALS_DISPERSION}getMaterialType(t){const n=this.parser.json.materials[t];return!n.extensions||!n.extensions[this.name]?null:Dn}extendMaterialParams(t,e){const i=this.parser.json.materials[t];if(!i.extensions||!i.extensions[this.name])return Promise.resolve();const s=i.extensions[this.name];return e.dispersion=s.dispersion!==void 0?s.dispersion:0,Promise.resolve()}}class ny{constructor(t){this.parser=t,this.name=zt.KHR_MATERIALS_IRIDESCENCE}getMaterialType(t){const n=this.parser.json.materials[t];return!n.extensions||!n.extensions[this.name]?null:Dn}extendMaterialParams(t,e){const n=this.parser,i=n.json.materials[t];if(!i.extensions||!i.extensions[this.name])return Promise.resolve();const s=[],a=i.extensions[this.name];return a.iridescenceFactor!==void 0&&(e.iridescence=a.iridescenceFactor),a.iridescenceTexture!==void 0&&s.push(n.assignTexture(e,"iridescenceMap",a.iridescenceTexture)),a.iridescenceIor!==void 0&&(e.iridescenceIOR=a.iridescenceIor),e.iridescenceThicknessRange===void 0&&(e.iridescenceThicknessRange=[100,400]),a.iridescenceThicknessMinimum!==void 0&&(e.iridescenceThicknessRange[0]=a.iridescenceThicknessMinimum),a.iridescenceThicknessMaximum!==void 0&&(e.iridescenceThicknessRange[1]=a.iridescenceThicknessMaximum),a.iridescenceThicknessTexture!==void 0&&s.push(n.assignTexture(e,"iridescenceThicknessMap",a.iridescenceThicknessTexture)),Promise.all(s)}}class iy{constructor(t){this.parser=t,this.name=zt.KHR_MATERIALS_SHEEN}getMaterialType(t){const n=this.parser.json.materials[t];return!n.extensions||!n.extensions[this.name]?null:Dn}extendMaterialParams(t,e){const n=this.parser,i=n.json.materials[t];if(!i.extensions||!i.extensions[this.name])return Promise.resolve();const s=[];e.sheenColor=new dt(0,0,0),e.sheenRoughness=0,e.sheen=1;const a=i.extensions[this.name];if(a.sheenColorFactor!==void 0){const o=a.sheenColorFactor;e.sheenColor.setRGB(o[0],o[1],o[2],qe)}return a.sheenRoughnessFactor!==void 0&&(e.sheenRoughness=a.sheenRoughnessFactor),a.sheenColorTexture!==void 0&&s.push(n.assignTexture(e,"sheenColorMap",a.sheenColorTexture,be)),a.sheenRoughnessTexture!==void 0&&s.push(n.assignTexture(e,"sheenRoughnessMap",a.sheenRoughnessTexture)),Promise.all(s)}}class sy{constructor(t){this.parser=t,this.name=zt.KHR_MATERIALS_TRANSMISSION}getMaterialType(t){const n=this.parser.json.materials[t];return!n.extensions||!n.extensions[this.name]?null:Dn}extendMaterialParams(t,e){const n=this.parser,i=n.json.materials[t];if(!i.extensions||!i.extensions[this.name])return Promise.resolve();const s=[],a=i.extensions[this.name];return a.transmissionFactor!==void 0&&(e.transmission=a.transmissionFactor),a.transmissionTexture!==void 0&&s.push(n.assignTexture(e,"transmissionMap",a.transmissionTexture)),Promise.all(s)}}class ry{constructor(t){this.parser=t,this.name=zt.KHR_MATERIALS_VOLUME}getMaterialType(t){const n=this.parser.json.materials[t];return!n.extensions||!n.extensions[this.name]?null:Dn}extendMaterialParams(t,e){const n=this.parser,i=n.json.materials[t];if(!i.extensions||!i.extensions[this.name])return Promise.resolve();const s=[],a=i.extensions[this.name];e.thickness=a.thicknessFactor!==void 0?a.thicknessFactor:0,a.thicknessTexture!==void 0&&s.push(n.assignTexture(e,"thicknessMap",a.thicknessTexture)),e.attenuationDistance=a.attenuationDistance||1/0;const o=a.attenuationColor||[1,1,1];return e.attenuationColor=new dt().setRGB(o[0],o[1],o[2],qe),Promise.all(s)}}class ay{constructor(t){this.parser=t,this.name=zt.KHR_MATERIALS_IOR}getMaterialType(t){const n=this.parser.json.materials[t];return!n.extensions||!n.extensions[this.name]?null:Dn}extendMaterialParams(t,e){const i=this.parser.json.materials[t];if(!i.extensions||!i.extensions[this.name])return Promise.resolve();const s=i.extensions[this.name];return e.ior=s.ior!==void 0?s.ior:1.5,Promise.resolve()}}class oy{constructor(t){this.parser=t,this.name=zt.KHR_MATERIALS_SPECULAR}getMaterialType(t){const n=this.parser.json.materials[t];return!n.extensions||!n.extensions[this.name]?null:Dn}extendMaterialParams(t,e){const n=this.parser,i=n.json.materials[t];if(!i.extensions||!i.extensions[this.name])return Promise.resolve();const s=[],a=i.extensions[this.name];e.specularIntensity=a.specularFactor!==void 0?a.specularFactor:1,a.specularTexture!==void 0&&s.push(n.assignTexture(e,"specularIntensityMap",a.specularTexture));const o=a.specularColorFactor||[1,1,1];return e.specularColor=new dt().setRGB(o[0],o[1],o[2],qe),a.specularColorTexture!==void 0&&s.push(n.assignTexture(e,"specularColorMap",a.specularColorTexture,be)),Promise.all(s)}}class ly{constructor(t){this.parser=t,this.name=zt.EXT_MATERIALS_BUMP}getMaterialType(t){const n=this.parser.json.materials[t];return!n.extensions||!n.extensions[this.name]?null:Dn}extendMaterialParams(t,e){const n=this.parser,i=n.json.materials[t];if(!i.extensions||!i.extensions[this.name])return Promise.resolve();const s=[],a=i.extensions[this.name];return e.bumpScale=a.bumpFactor!==void 0?a.bumpFactor:1,a.bumpTexture!==void 0&&s.push(n.assignTexture(e,"bumpMap",a.bumpTexture)),Promise.all(s)}}class cy{constructor(t){this.parser=t,this.name=zt.KHR_MATERIALS_ANISOTROPY}getMaterialType(t){const n=this.parser.json.materials[t];return!n.extensions||!n.extensions[this.name]?null:Dn}extendMaterialParams(t,e){const n=this.parser,i=n.json.materials[t];if(!i.extensions||!i.extensions[this.name])return Promise.resolve();const s=[],a=i.extensions[this.name];return a.anisotropyStrength!==void 0&&(e.anisotropy=a.anisotropyStrength),a.anisotropyRotation!==void 0&&(e.anisotropyRotation=a.anisotropyRotation),a.anisotropyTexture!==void 0&&s.push(n.assignTexture(e,"anisotropyMap",a.anisotropyTexture)),Promise.all(s)}}class hy{constructor(t){this.parser=t,this.name=zt.KHR_TEXTURE_BASISU}loadTexture(t){const e=this.parser,n=e.json,i=n.textures[t];if(!i.extensions||!i.extensions[this.name])return null;const s=i.extensions[this.name],a=e.options.ktx2Loader;if(!a){if(n.extensionsRequired&&n.extensionsRequired.indexOf(this.name)>=0)throw new Error("THREE.GLTFLoader: setKTX2Loader must be called before loading KTX2 textures");return null}return e.loadTextureImage(t,s.source,a)}}class uy{constructor(t){this.parser=t,this.name=zt.EXT_TEXTURE_WEBP,this.isSupported=null}loadTexture(t){const e=this.name,n=this.parser,i=n.json,s=i.textures[t];if(!s.extensions||!s.extensions[e])return null;const a=s.extensions[e],o=i.images[a.source];let l=n.textureLoader;if(o.uri){const c=n.options.manager.getHandler(o.uri);c!==null&&(l=c)}return this.detectSupport().then(function(c){if(c)return n.loadTextureImage(t,a.source,l);if(i.extensionsRequired&&i.extensionsRequired.indexOf(e)>=0)throw new Error("THREE.GLTFLoader: WebP required by asset but unsupported.");return n.loadTexture(t)})}detectSupport(){return this.isSupported||(this.isSupported=new Promise(function(t){const e=new Image;e.src="data:image/webp;base64,UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA",e.onload=e.onerror=function(){t(e.height===1)}})),this.isSupported}}class dy{constructor(t){this.parser=t,this.name=zt.EXT_TEXTURE_AVIF,this.isSupported=null}loadTexture(t){const e=this.name,n=this.parser,i=n.json,s=i.textures[t];if(!s.extensions||!s.extensions[e])return null;const a=s.extensions[e],o=i.images[a.source];let l=n.textureLoader;if(o.uri){const c=n.options.manager.getHandler(o.uri);c!==null&&(l=c)}return this.detectSupport().then(function(c){if(c)return n.loadTextureImage(t,a.source,l);if(i.extensionsRequired&&i.extensionsRequired.indexOf(e)>=0)throw new Error("THREE.GLTFLoader: AVIF required by asset but unsupported.");return n.loadTexture(t)})}detectSupport(){return this.isSupported||(this.isSupported=new Promise(function(t){const e=new Image;e.src="data:image/avif;base64,AAAAIGZ0eXBhdmlmAAAAAGF2aWZtaWYxbWlhZk1BMUIAAADybWV0YQAAAAAAAAAoaGRscgAAAAAAAAAAcGljdAAAAAAAAAAAAAAAAGxpYmF2aWYAAAAADnBpdG0AAAAAAAEAAAAeaWxvYwAAAABEAAABAAEAAAABAAABGgAAABcAAAAoaWluZgAAAAAAAQAAABppbmZlAgAAAAABAABhdjAxQ29sb3IAAAAAamlwcnAAAABLaXBjbwAAABRpc3BlAAAAAAAAAAEAAAABAAAAEHBpeGkAAAAAAwgICAAAAAxhdjFDgQAMAAAAABNjb2xybmNseAACAAIABoAAAAAXaXBtYQAAAAAAAAABAAEEAQKDBAAAAB9tZGF0EgAKCBgABogQEDQgMgkQAAAAB8dSLfI=",e.onload=e.onerror=function(){t(e.height===1)}})),this.isSupported}}class fy{constructor(t){this.name=zt.EXT_MESHOPT_COMPRESSION,this.parser=t}loadBufferView(t){const e=this.parser.json,n=e.bufferViews[t];if(n.extensions&&n.extensions[this.name]){const i=n.extensions[this.name],s=this.parser.getDependency("buffer",i.buffer),a=this.parser.options.meshoptDecoder;if(!a||!a.supported){if(e.extensionsRequired&&e.extensionsRequired.indexOf(this.name)>=0)throw new Error("THREE.GLTFLoader: setMeshoptDecoder must be called before loading compressed files");return null}return s.then(function(o){const l=i.byteOffset||0,c=i.byteLength||0,h=i.count,u=i.byteStride,d=new Uint8Array(o,l,c);return a.decodeGltfBufferAsync?a.decodeGltfBufferAsync(h,u,d,i.mode,i.filter).then(function(f){return f.buffer}):a.ready.then(function(){const f=new ArrayBuffer(h*u);return a.decodeGltfBuffer(new Uint8Array(f),h,u,d,i.mode,i.filter),f})})}else return null}}class py{constructor(t){this.name=zt.EXT_MESH_GPU_INSTANCING,this.parser=t}createNodeMesh(t){const e=this.parser.json,n=e.nodes[t];if(!n.extensions||!n.extensions[this.name]||n.mesh===void 0)return null;const i=e.meshes[n.mesh];for(const c of i.primitives)if(c.mode!==ln.TRIANGLES&&c.mode!==ln.TRIANGLE_STRIP&&c.mode!==ln.TRIANGLE_FAN&&c.mode!==void 0)return null;const a=n.extensions[this.name].attributes,o=[],l={};for(const c in a)o.push(this.parser.getDependency("accessor",a[c]).then(h=>(l[c]=h,l[c])));return o.length<1?null:(o.push(this.parser.createNodeMesh(t)),Promise.all(o).then(c=>{const h=c.pop(),u=h.isGroup?h.children:[h],d=c[0].count,f=[];for(const m of u){const v=new It,g=new P,p=new xi,x=new P(1,1,1),y=new Ni(m.geometry,m.material,d);for(let _=0;_<d;_++)l.TRANSLATION&&g.fromBufferAttribute(l.TRANSLATION,_),l.ROTATION&&p.fromBufferAttribute(l.ROTATION,_),l.SCALE&&x.fromBufferAttribute(l.SCALE,_),y.setMatrixAt(_,v.compose(g,p,x));for(const _ in l)if(_==="_COLOR_0"){const I=l[_];y.instanceColor=new Qs(I.array,I.itemSize,I.normalized)}else _!=="TRANSLATION"&&_!=="ROTATION"&&_!=="SCALE"&&m.geometry.setAttribute(_,l[_]);he.prototype.copy.call(y,m),this.parser.assignFinalMaterial(y),f.push(y)}return h.isGroup?(h.clear(),h.add(...f),h):f[0]}))}}const Xu="glTF",ks=12,Th={JSON:1313821514,BIN:5130562};class my{constructor(t){this.name=zt.KHR_BINARY_GLTF,this.content=null,this.body=null;const e=new DataView(t,0,ks),n=new TextDecoder;if(this.header={magic:n.decode(new Uint8Array(t.slice(0,4))),version:e.getUint32(4,!0),length:e.getUint32(8,!0)},this.header.magic!==Xu)throw new Error("THREE.GLTFLoader: Unsupported glTF-Binary header.");if(this.header.version<2)throw new Error("THREE.GLTFLoader: Legacy binary file detected.");const i=this.header.length-ks,s=new DataView(t,ks);let a=0;for(;a<i;){const o=s.getUint32(a,!0);a+=4;const l=s.getUint32(a,!0);if(a+=4,l===Th.JSON){const c=new Uint8Array(t,ks+a,o);this.content=n.decode(c)}else if(l===Th.BIN){const c=ks+a;this.body=t.slice(c,c+o)}a+=o}if(this.content===null)throw new Error("THREE.GLTFLoader: JSON content not found.")}}class gy{constructor(t,e){if(!e)throw new Error("THREE.GLTFLoader: No DRACOLoader instance provided.");this.name=zt.KHR_DRACO_MESH_COMPRESSION,this.json=t,this.dracoLoader=e,this.dracoLoader.preload()}decodePrimitive(t,e){const n=this.json,i=this.dracoLoader,s=t.extensions[this.name].bufferView,a=t.extensions[this.name].attributes,o={},l={},c={};for(const h in a){const u=jo[h]||h.toLowerCase();o[u]=a[h]}for(const h in t.attributes){const u=jo[h]||h.toLowerCase();if(a[h]!==void 0){const d=n.accessors[t.attributes[h]],f=rs[d.componentType];c[u]=f.name,l[u]=d.normalized===!0}}return e.getDependency("bufferView",s).then(function(h){return new Promise(function(u,d){i.decodeDracoFile(h,function(f){for(const m in f.attributes){const v=f.attributes[m],g=l[m];g!==void 0&&(v.normalized=g)}u(f)},o,c,qe,d)})})}}class vy{constructor(){this.name=zt.KHR_TEXTURE_TRANSFORM}extendTexture(t,e){return(e.texCoord===void 0||e.texCoord===t.channel)&&e.offset===void 0&&e.rotation===void 0&&e.scale===void 0||(t=t.clone(),e.texCoord!==void 0&&(t.channel=e.texCoord),e.offset!==void 0&&t.offset.fromArray(e.offset),e.rotation!==void 0&&(t.rotation=e.rotation),e.scale!==void 0&&t.repeat.fromArray(e.scale),t.needsUpdate=!0),t}}class _y{constructor(){this.name=zt.KHR_MESH_QUANTIZATION}}class qu extends rr{constructor(t,e,n,i){super(t,e,n,i)}copySampleValue_(t){const e=this.resultBuffer,n=this.sampleValues,i=this.valueSize,s=t*i*3+i;for(let a=0;a!==i;a++)e[a]=n[s+a];return e}interpolate_(t,e,n,i){const s=this.resultBuffer,a=this.sampleValues,o=this.valueSize,l=o*2,c=o*3,h=i-e,u=(n-e)/h,d=u*u,f=d*u,m=t*c,v=m-c,g=-2*f+3*d,p=f-d,x=1-g,y=p-d+u;for(let _=0;_!==o;_++){const I=a[v+_+o],E=a[v+_+l]*h,A=a[m+_+o],C=a[m+_]*h;s[_]=x*I+y*E+g*A+p*C}return s}}const xy=new xi;class yy extends qu{interpolate_(t,e,n,i){const s=super.interpolate_(t,e,n,i);return xy.fromArray(s).normalize().toArray(s),s}}const ln={POINTS:0,LINES:1,LINE_LOOP:2,LINE_STRIP:3,TRIANGLES:4,TRIANGLE_STRIP:5,TRIANGLE_FAN:6},rs={5120:Int8Array,5121:Uint8Array,5122:Int16Array,5123:Uint16Array,5125:Uint32Array,5126:Float32Array},Eh={9728:Xe,9729:tn,9984:kh,9985:Br,9986:Bs,9987:qn},Ah={33071:fi,33648:$r,10497:vi},Qa={SCALAR:1,VEC2:2,VEC3:3,VEC4:4,MAT2:4,MAT3:9,MAT4:16},jo={POSITION:"position",NORMAL:"normal",TANGENT:"tangent",TEXCOORD_0:"uv",TEXCOORD_1:"uv1",TEXCOORD_2:"uv2",TEXCOORD_3:"uv3",COLOR_0:"color",WEIGHTS_0:"skinWeight",JOINTS_0:"skinIndex"},hi={scale:"scale",translation:"position",rotation:"quaternion",weights:"morphTargetInfluences"},My={CUBICSPLINE:void 0,LINEAR:js,STEP:$s},to={OPAQUE:"OPAQUE",MASK:"MASK",BLEND:"BLEND"};function by(r){return r.DefaultMaterial===void 0&&(r.DefaultMaterial=new Tl({color:16777215,emissive:0,metalness:1,roughness:1,transparent:!1,depthTest:!0,side:Zn})),r.DefaultMaterial}function Ai(r,t,e){for(const n in e.extensions)r[n]===void 0&&(t.userData.gltfExtensions=t.userData.gltfExtensions||{},t.userData.gltfExtensions[n]=e.extensions[n])}function Xn(r,t){t.extras!==void 0&&(typeof t.extras=="object"?Object.assign(r.userData,t.extras):console.warn("THREE.GLTFLoader: Ignoring primitive type .extras, "+t.extras))}function Sy(r,t,e){let n=!1,i=!1,s=!1;for(let c=0,h=t.length;c<h;c++){const u=t[c];if(u.POSITION!==void 0&&(n=!0),u.NORMAL!==void 0&&(i=!0),u.COLOR_0!==void 0&&(s=!0),n&&i&&s)break}if(!n&&!i&&!s)return Promise.resolve(r);const a=[],o=[],l=[];for(let c=0,h=t.length;c<h;c++){const u=t[c];if(n){const d=u.POSITION!==void 0?e.getDependency("accessor",u.POSITION):r.attributes.position;a.push(d)}if(i){const d=u.NORMAL!==void 0?e.getDependency("accessor",u.NORMAL):r.attributes.normal;o.push(d)}if(s){const d=u.COLOR_0!==void 0?e.getDependency("accessor",u.COLOR_0):r.attributes.color;l.push(d)}}return Promise.all([Promise.all(a),Promise.all(o),Promise.all(l)]).then(function(c){const h=c[0],u=c[1],d=c[2];return n&&(r.morphAttributes.position=h),i&&(r.morphAttributes.normal=u),s&&(r.morphAttributes.color=d),r.morphTargetsRelative=!0,r})}function wy(r,t){if(r.updateMorphTargets(),t.weights!==void 0)for(let e=0,n=t.weights.length;e<n;e++)r.morphTargetInfluences[e]=t.weights[e];if(t.extras&&Array.isArray(t.extras.targetNames)){const e=t.extras.targetNames;if(r.morphTargetInfluences.length===e.length){r.morphTargetDictionary={};for(let n=0,i=e.length;n<i;n++)r.morphTargetDictionary[e[n]]=n}else console.warn("THREE.GLTFLoader: Invalid extras.targetNames length. Ignoring names.")}}function Ty(r){let t;const e=r.extensions&&r.extensions[zt.KHR_DRACO_MESH_COMPRESSION];if(e?t="draco:"+e.bufferView+":"+e.indices+":"+eo(e.attributes):t=r.indices+":"+eo(r.attributes)+":"+r.mode,r.targets!==void 0)for(let n=0,i=r.targets.length;n<i;n++)t+=":"+eo(r.targets[n]);return t}function eo(r){let t="";const e=Object.keys(r).sort();for(let n=0,i=e.length;n<i;n++)t+=e[n]+":"+r[e[n]]+";";return t}function Zo(r){switch(r){case Int8Array:return 1/127;case Uint8Array:return 1/255;case Int16Array:return 1/32767;case Uint16Array:return 1/65535;default:throw new Error("THREE.GLTFLoader: Unsupported normalized accessor component type.")}}function Ey(r){return r.search(/\.jpe?g($|\?)/i)>0||r.search(/^data\:image\/jpeg/)===0?"image/jpeg":r.search(/\.webp($|\?)/i)>0||r.search(/^data\:image\/webp/)===0?"image/webp":r.search(/\.ktx2($|\?)/i)>0||r.search(/^data\:image\/ktx2/)===0?"image/ktx2":"image/png"}const Ay=new It;class Ry{constructor(t={},e={}){this.json=t,this.extensions={},this.plugins={},this.options=e,this.cache=new jx,this.associations=new Map,this.primitiveCache={},this.nodeCache={},this.meshCache={refs:{},uses:{}},this.cameraCache={refs:{},uses:{}},this.lightCache={refs:{},uses:{}},this.sourceCache={},this.textureCache={},this.nodeNamesUsed={};let n=!1,i=-1,s=!1,a=-1;if(typeof navigator<"u"){const o=navigator.userAgent;n=/^((?!chrome|android).)*safari/i.test(o)===!0;const l=o.match(/Version\/(\d+)/);i=n&&l?parseInt(l[1],10):-1,s=o.indexOf("Firefox")>-1,a=s?o.match(/Firefox\/([0-9]+)\./)[1]:-1}typeof createImageBitmap>"u"||n&&i<17||s&&a<98?this.textureLoader=new Xv(this.options.manager):this.textureLoader=new Jv(this.options.manager),this.textureLoader.setCrossOrigin(this.options.crossOrigin),this.textureLoader.setRequestHeader(this.options.requestHeader),this.fileLoader=new Su(this.options.manager),this.fileLoader.setResponseType("arraybuffer"),this.options.crossOrigin==="use-credentials"&&this.fileLoader.setWithCredentials(!0)}setExtensions(t){this.extensions=t}setPlugins(t){this.plugins=t}parse(t,e){const n=this,i=this.json,s=this.extensions;this.cache.removeAll(),this.nodeCache={},this._invokeAll(function(a){return a._markDefs&&a._markDefs()}),Promise.all(this._invokeAll(function(a){return a.beforeRoot&&a.beforeRoot()})).then(function(){return Promise.all([n.getDependencies("scene"),n.getDependencies("animation"),n.getDependencies("camera")])}).then(function(a){const o={scene:a[0][i.scene||0],scenes:a[0],animations:a[1],cameras:a[2],asset:i.asset,parser:n,userData:{}};return Ai(s,o,i),Xn(o,i),Promise.all(n._invokeAll(function(l){return l.afterRoot&&l.afterRoot(o)})).then(function(){for(const l of o.scenes)l.updateMatrixWorld();t(o)})}).catch(e)}_markDefs(){const t=this.json.nodes||[],e=this.json.skins||[],n=this.json.meshes||[];for(let i=0,s=e.length;i<s;i++){const a=e[i].joints;for(let o=0,l=a.length;o<l;o++)t[a[o]].isBone=!0}for(let i=0,s=t.length;i<s;i++){const a=t[i];a.mesh!==void 0&&(this._addNodeRef(this.meshCache,a.mesh),a.skin!==void 0&&(n[a.mesh].isSkinnedMesh=!0)),a.camera!==void 0&&this._addNodeRef(this.cameraCache,a.camera)}}_addNodeRef(t,e){e!==void 0&&(t.refs[e]===void 0&&(t.refs[e]=t.uses[e]=0),t.refs[e]++)}_getNodeRef(t,e,n){if(t.refs[e]<=1)return n;const i=n.clone(),s=(a,o)=>{const l=this.associations.get(a);l!=null&&this.associations.set(o,l);for(const[c,h]of a.children.entries())s(h,o.children[c])};return s(n,i),i.name+="_instance_"+t.uses[e]++,i}_invokeOne(t){const e=Object.values(this.plugins);e.push(this);for(let n=0;n<e.length;n++){const i=t(e[n]);if(i)return i}return null}_invokeAll(t){const e=Object.values(this.plugins);e.unshift(this);const n=[];for(let i=0;i<e.length;i++){const s=t(e[i]);s&&n.push(s)}return n}getDependency(t,e){const n=t+":"+e;let i=this.cache.get(n);if(!i){switch(t){case"scene":i=this.loadScene(e);break;case"node":i=this._invokeOne(function(s){return s.loadNode&&s.loadNode(e)});break;case"mesh":i=this._invokeOne(function(s){return s.loadMesh&&s.loadMesh(e)});break;case"accessor":i=this.loadAccessor(e);break;case"bufferView":i=this._invokeOne(function(s){return s.loadBufferView&&s.loadBufferView(e)});break;case"buffer":i=this.loadBuffer(e);break;case"material":i=this._invokeOne(function(s){return s.loadMaterial&&s.loadMaterial(e)});break;case"texture":i=this._invokeOne(function(s){return s.loadTexture&&s.loadTexture(e)});break;case"skin":i=this.loadSkin(e);break;case"animation":i=this._invokeOne(function(s){return s.loadAnimation&&s.loadAnimation(e)});break;case"camera":i=this.loadCamera(e);break;default:if(i=this._invokeOne(function(s){return s!=this&&s.getDependency&&s.getDependency(t,e)}),!i)throw new Error("Unknown type: "+t);break}this.cache.add(n,i)}return i}getDependencies(t){let e=this.cache.get(t);if(!e){const n=this,i=this.json[t+(t==="mesh"?"es":"s")]||[];e=Promise.all(i.map(function(s,a){return n.getDependency(t,a)})),this.cache.add(t,e)}return e}loadBuffer(t){const e=this.json.buffers[t],n=this.fileLoader;if(e.type&&e.type!=="arraybuffer")throw new Error("THREE.GLTFLoader: "+e.type+" buffer type is not supported.");if(e.uri===void 0&&t===0)return Promise.resolve(this.extensions[zt.KHR_BINARY_GLTF].body);const i=this.options;return new Promise(function(s,a){n.load(qs.resolveURL(e.uri,i.path),s,void 0,function(){a(new Error('THREE.GLTFLoader: Failed to load buffer "'+e.uri+'".'))})})}loadBufferView(t){const e=this.json.bufferViews[t];return this.getDependency("buffer",e.buffer).then(function(n){const i=e.byteLength||0,s=e.byteOffset||0;return n.slice(s,s+i)})}loadAccessor(t){const e=this,n=this.json,i=this.json.accessors[t];if(i.bufferView===void 0&&i.sparse===void 0){const a=Qa[i.type],o=rs[i.componentType],l=i.normalized===!0,c=new o(i.count*a);return Promise.resolve(new ge(c,a,l))}const s=[];return i.bufferView!==void 0?s.push(this.getDependency("bufferView",i.bufferView)):s.push(null),i.sparse!==void 0&&(s.push(this.getDependency("bufferView",i.sparse.indices.bufferView)),s.push(this.getDependency("bufferView",i.sparse.values.bufferView))),Promise.all(s).then(function(a){const o=a[0],l=Qa[i.type],c=rs[i.componentType],h=c.BYTES_PER_ELEMENT,u=h*l,d=i.byteOffset||0,f=i.bufferView!==void 0?n.bufferViews[i.bufferView].byteStride:void 0,m=i.normalized===!0;let v,g;if(f&&f!==u){const p=Math.floor(d/f),x="InterleavedBuffer:"+i.bufferView+":"+i.componentType+":"+p+":"+i.count;let y=e.cache.get(x);y||(v=new c(o,p*f,i.count*f/h),y=new hv(v,f/h),e.cache.add(x,y)),g=new ml(y,l,d%f/h,m)}else o===null?v=new c(i.count*l):v=new c(o,d,i.count*l),g=new ge(v,l,m);if(i.sparse!==void 0){const p=Qa.SCALAR,x=rs[i.sparse.indices.componentType],y=i.sparse.indices.byteOffset||0,_=i.sparse.values.byteOffset||0,I=new x(a[1],y,i.sparse.count*p),E=new c(a[2],_,i.sparse.count*l);o!==null&&(g=new ge(g.array.slice(),g.itemSize,g.normalized)),g.normalized=!1;for(let A=0,C=I.length;A<C;A++){const b=I[A];if(g.setX(b,E[A*l]),l>=2&&g.setY(b,E[A*l+1]),l>=3&&g.setZ(b,E[A*l+2]),l>=4&&g.setW(b,E[A*l+3]),l>=5)throw new Error("THREE.GLTFLoader: Unsupported itemSize in sparse BufferAttribute.")}g.normalized=m}return g})}loadTexture(t){const e=this.json,n=this.options,s=e.textures[t].source,a=e.images[s];let o=this.textureLoader;if(a.uri){const l=n.manager.getHandler(a.uri);l!==null&&(o=l)}return this.loadTextureImage(t,s,o)}loadTextureImage(t,e,n){const i=this,s=this.json,a=s.textures[t],o=s.images[e],l=(o.uri||o.bufferView)+":"+a.sampler;if(this.textureCache[l])return this.textureCache[l];const c=this.loadImageSource(e,n).then(function(h){h.flipY=!1,h.name=a.name||o.name||"",h.name===""&&typeof o.uri=="string"&&o.uri.startsWith("data:image/")===!1&&(h.name=o.uri);const d=(s.samplers||{})[a.sampler]||{};return h.magFilter=Eh[d.magFilter]||tn,h.minFilter=Eh[d.minFilter]||qn,h.wrapS=Ah[d.wrapS]||vi,h.wrapT=Ah[d.wrapT]||vi,h.generateMipmaps=!h.isCompressedTexture&&h.minFilter!==Xe&&h.minFilter!==tn,i.associations.set(h,{textures:t}),h}).catch(function(){return null});return this.textureCache[l]=c,c}loadImageSource(t,e){const n=this,i=this.json,s=this.options;if(this.sourceCache[t]!==void 0)return this.sourceCache[t].then(u=>u.clone());const a=i.images[t],o=self.URL||self.webkitURL;let l=a.uri||"",c=!1;if(a.bufferView!==void 0)l=n.getDependency("bufferView",a.bufferView).then(function(u){c=!0;const d=new Blob([u],{type:a.mimeType});return l=o.createObjectURL(d),l});else if(a.uri===void 0)throw new Error("THREE.GLTFLoader: Image "+t+" is missing URI and bufferView");const h=Promise.resolve(l).then(function(u){return new Promise(function(d,f){let m=d;e.isImageBitmapLoader===!0&&(m=function(v){const g=new Ce(v);g.needsUpdate=!0,d(g)}),e.load(qs.resolveURL(u,s.path),m,void 0,f)})}).then(function(u){return c===!0&&o.revokeObjectURL(l),Xn(u,a),u.userData.mimeType=a.mimeType||Ey(a.uri),u}).catch(function(u){throw console.error("THREE.GLTFLoader: Couldn't load texture",l),u});return this.sourceCache[t]=h,h}assignTexture(t,e,n,i){const s=this;return this.getDependency("texture",n.index).then(function(a){if(!a)return null;if(n.texCoord!==void 0&&n.texCoord>0&&(a=a.clone(),a.channel=n.texCoord),s.extensions[zt.KHR_TEXTURE_TRANSFORM]){const o=n.extensions!==void 0?n.extensions[zt.KHR_TEXTURE_TRANSFORM]:void 0;if(o){const l=s.associations.get(a);a=s.extensions[zt.KHR_TEXTURE_TRANSFORM].extendTexture(a,o),s.associations.set(a,l)}}return i!==void 0&&(a.colorSpace=i),t[e]=a,a})}assignFinalMaterial(t){const e=t.geometry;let n=t.material;const i=e.attributes.tangent===void 0,s=e.attributes.color!==void 0,a=e.attributes.normal===void 0;if(t.isPoints){const o="PointsMaterial:"+n.uuid;let l=this.cache.get(o);l||(l=new gu,Tn.prototype.copy.call(l,n),l.color.copy(n.color),l.map=n.map,l.sizeAttenuation=!1,this.cache.add(o,l)),n=l}else if(t.isLine){const o="LineBasicMaterial:"+n.uuid;let l=this.cache.get(o);l||(l=new mu,Tn.prototype.copy.call(l,n),l.color.copy(n.color),l.map=n.map,this.cache.add(o,l)),n=l}if(i||s||a){let o="ClonedMaterial:"+n.uuid+":";i&&(o+="derivative-tangents:"),s&&(o+="vertex-colors:"),a&&(o+="flat-shading:");let l=this.cache.get(o);l||(l=n.clone(),s&&(l.vertexColors=!0),a&&(l.flatShading=!0),i&&(l.normalScale&&(l.normalScale.y*=-1),l.clearcoatNormalScale&&(l.clearcoatNormalScale.y*=-1)),this.cache.add(o,l),this.associations.set(l,this.associations.get(n))),n=l}t.material=n}getMaterialType(){return Tl}loadMaterial(t){const e=this,n=this.json,i=this.extensions,s=n.materials[t];let a;const o={},l=s.extensions||{},c=[];if(l[zt.KHR_MATERIALS_UNLIT]){const u=i[zt.KHR_MATERIALS_UNLIT];a=u.getMaterialType(),c.push(u.extendParams(o,s,e))}else{const u=s.pbrMetallicRoughness||{};if(o.color=new dt(1,1,1),o.opacity=1,Array.isArray(u.baseColorFactor)){const d=u.baseColorFactor;o.color.setRGB(d[0],d[1],d[2],qe),o.opacity=d[3]}u.baseColorTexture!==void 0&&c.push(e.assignTexture(o,"map",u.baseColorTexture,be)),o.metalness=u.metallicFactor!==void 0?u.metallicFactor:1,o.roughness=u.roughnessFactor!==void 0?u.roughnessFactor:1,u.metallicRoughnessTexture!==void 0&&(c.push(e.assignTexture(o,"metalnessMap",u.metallicRoughnessTexture)),c.push(e.assignTexture(o,"roughnessMap",u.metallicRoughnessTexture))),a=this._invokeOne(function(d){return d.getMaterialType&&d.getMaterialType(t)}),c.push(Promise.all(this._invokeAll(function(d){return d.extendMaterialParams&&d.extendMaterialParams(t,o)})))}s.doubleSided===!0&&(o.side=hn);const h=s.alphaMode||to.OPAQUE;if(h===to.BLEND?(o.transparent=!0,o.depthWrite=!1):(o.transparent=!1,h===to.MASK&&(o.alphaTest=s.alphaCutoff!==void 0?s.alphaCutoff:.5)),s.normalTexture!==void 0&&a!==ne&&(c.push(e.assignTexture(o,"normalMap",s.normalTexture)),o.normalScale=new nt(1,1),s.normalTexture.scale!==void 0)){const u=s.normalTexture.scale;o.normalScale.set(u,u)}if(s.occlusionTexture!==void 0&&a!==ne&&(c.push(e.assignTexture(o,"aoMap",s.occlusionTexture)),s.occlusionTexture.strength!==void 0&&(o.aoMapIntensity=s.occlusionTexture.strength)),s.emissiveFactor!==void 0&&a!==ne){const u=s.emissiveFactor;o.emissive=new dt().setRGB(u[0],u[1],u[2],qe)}return s.emissiveTexture!==void 0&&a!==ne&&c.push(e.assignTexture(o,"emissiveMap",s.emissiveTexture,be)),Promise.all(c).then(function(){const u=new a(o);return s.name&&(u.name=s.name),Xn(u,s),e.associations.set(u,{materials:t}),s.extensions&&Ai(i,u,s),u})}createUniqueName(t){const e=oe.sanitizeNodeName(t||"");return e in this.nodeNamesUsed?e+"_"+ ++this.nodeNamesUsed[e]:(this.nodeNamesUsed[e]=0,e)}loadGeometries(t){const e=this,n=this.extensions,i=this.primitiveCache;function s(o){return n[zt.KHR_DRACO_MESH_COMPRESSION].decodePrimitive(o,e).then(function(l){return Rh(l,o,e)})}const a=[];for(let o=0,l=t.length;o<l;o++){const c=t[o],h=Ty(c),u=i[h];if(u)a.push(u.promise);else{let d;c.extensions&&c.extensions[zt.KHR_DRACO_MESH_COMPRESSION]?d=s(c):d=Rh(new ye,c,e),i[h]={primitive:c,promise:d},a.push(d)}}return Promise.all(a)}loadMesh(t){const e=this,n=this.json,i=this.extensions,s=n.meshes[t],a=s.primitives,o=[];for(let l=0,c=a.length;l<c;l++){const h=a[l].material===void 0?by(this.cache):this.getDependency("material",a[l].material);o.push(h)}return o.push(e.loadGeometries(a)),Promise.all(o).then(function(l){const c=l.slice(0,l.length-1),h=l[l.length-1],u=[];for(let f=0,m=h.length;f<m;f++){const v=h[f],g=a[f];let p;const x=c[f];if(g.mode===ln.TRIANGLES||g.mode===ln.TRIANGLE_STRIP||g.mode===ln.TRIANGLE_FAN||g.mode===void 0)p=s.isSkinnedMesh===!0?new dv(v,x):new Rt(v,x),p.isSkinnedMesh===!0&&p.normalizeSkinWeights(),g.mode===ln.TRIANGLE_STRIP?p.geometry=_h(p.geometry,Kh):g.mode===ln.TRIANGLE_FAN&&(p.geometry=_h(p.geometry,zo));else if(g.mode===ln.LINES)p=new mv(v,x);else if(g.mode===ln.LINE_STRIP)p=new vl(v,x);else if(g.mode===ln.LINE_LOOP)p=new gv(v,x);else if(g.mode===ln.POINTS)p=new _l(v,x);else throw new Error("THREE.GLTFLoader: Primitive mode unsupported: "+g.mode);Object.keys(p.geometry.morphAttributes).length>0&&wy(p,s),p.name=e.createUniqueName(s.name||"mesh_"+t),Xn(p,s),g.extensions&&Ai(i,p,g),e.assignFinalMaterial(p),u.push(p)}for(let f=0,m=u.length;f<m;f++)e.associations.set(u[f],{meshes:t,primitives:f});if(u.length===1)return s.extensions&&Ai(i,u[0],s),u[0];const d=new De;s.extensions&&Ai(i,d,s),e.associations.set(d,{meshes:t});for(let f=0,m=u.length;f<m;f++)d.add(u[f]);return d})}loadCamera(t){let e;const n=this.json.cameras[t],i=n[n.type];if(!i){console.warn("THREE.GLTFLoader: Missing camera parameters.");return}return n.type==="perspective"?e=new ze(jh.radToDeg(i.yfov),i.aspectRatio||1,i.znear||1,i.zfar||2e6):n.type==="orthographic"&&(e=new aa(-i.xmag,i.xmag,i.ymag,-i.ymag,i.znear,i.zfar)),n.name&&(e.name=this.createUniqueName(n.name)),Xn(e,n),Promise.resolve(e)}loadSkin(t){const e=this.json.skins[t],n=[];for(let i=0,s=e.joints.length;i<s;i++)n.push(this._loadNodeShallow(e.joints[i]));return e.inverseBindMatrices!==void 0?n.push(this.getDependency("accessor",e.inverseBindMatrices)):n.push(null),Promise.all(n).then(function(i){const s=i.pop(),a=i,o=[],l=[];for(let c=0,h=a.length;c<h;c++){const u=a[c];if(u){o.push(u);const d=new It;s!==null&&d.fromArray(s.array,c*16),l.push(d)}else console.warn('THREE.GLTFLoader: Joint "%s" could not be found.',e.joints[c])}return new gl(o,l)})}loadAnimation(t){const e=this.json,n=this,i=e.animations[t],s=i.name?i.name:"animation_"+t,a=[],o=[],l=[],c=[],h=[];for(let u=0,d=i.channels.length;u<d;u++){const f=i.channels[u],m=i.samplers[f.sampler],v=f.target,g=v.node,p=i.parameters!==void 0?i.parameters[m.input]:m.input,x=i.parameters!==void 0?i.parameters[m.output]:m.output;v.node!==void 0&&(a.push(this.getDependency("node",g)),o.push(this.getDependency("accessor",p)),l.push(this.getDependency("accessor",x)),c.push(m),h.push(v))}return Promise.all([Promise.all(a),Promise.all(o),Promise.all(l),Promise.all(c),Promise.all(h)]).then(function(u){const d=u[0],f=u[1],m=u[2],v=u[3],g=u[4],p=[];for(let x=0,y=d.length;x<y;x++){const _=d[x],I=f[x],E=m[x],A=v[x],C=g[x];if(_===void 0)continue;_.updateMatrix&&_.updateMatrix();const b=n._createAnimationTracks(_,I,E,A,C);if(b)for(let M=0;M<b.length;M++)p.push(b[M])}return new kv(s,void 0,p)})}createNodeMesh(t){const e=this.json,n=this,i=e.nodes[t];return i.mesh===void 0?null:n.getDependency("mesh",i.mesh).then(function(s){const a=n._getNodeRef(n.meshCache,i.mesh,s);return i.weights!==void 0&&a.traverse(function(o){if(o.isMesh)for(let l=0,c=i.weights.length;l<c;l++)o.morphTargetInfluences[l]=i.weights[l]}),a})}loadNode(t){const e=this.json,n=this,i=e.nodes[t],s=n._loadNodeShallow(t),a=[],o=i.children||[];for(let c=0,h=o.length;c<h;c++)a.push(n.getDependency("node",o[c]));const l=i.skin===void 0?Promise.resolve(null):n.getDependency("skin",i.skin);return Promise.all([s,Promise.all(a),l]).then(function(c){const h=c[0],u=c[1],d=c[2];d!==null&&h.traverse(function(f){f.isSkinnedMesh&&f.bind(d,Ay)});for(let f=0,m=u.length;f<m;f++)h.add(u[f]);return h})}_loadNodeShallow(t){const e=this.json,n=this.extensions,i=this;if(this.nodeCache[t]!==void 0)return this.nodeCache[t];const s=e.nodes[t],a=s.name?i.createUniqueName(s.name):"",o=[],l=i._invokeOne(function(c){return c.createNodeMesh&&c.createNodeMesh(t)});return l&&o.push(l),s.camera!==void 0&&o.push(i.getDependency("camera",s.camera).then(function(c){return i._getNodeRef(i.cameraCache,s.camera,c)})),i._invokeAll(function(c){return c.createNodeAttachment&&c.createNodeAttachment(t)}).forEach(function(c){o.push(c)}),this.nodeCache[t]=Promise.all(o).then(function(c){let h;if(s.isBone===!0?h=new fu:c.length>1?h=new De:c.length===1?h=c[0]:h=new he,h!==c[0])for(let u=0,d=c.length;u<d;u++)h.add(c[u]);if(s.name&&(h.userData.name=s.name,h.name=a),Xn(h,s),s.extensions&&Ai(n,h,s),s.matrix!==void 0){const u=new It;u.fromArray(s.matrix),h.applyMatrix4(u)}else s.translation!==void 0&&h.position.fromArray(s.translation),s.rotation!==void 0&&h.quaternion.fromArray(s.rotation),s.scale!==void 0&&h.scale.fromArray(s.scale);return i.associations.has(h)||i.associations.set(h,{}),i.associations.get(h).nodes=t,h}),this.nodeCache[t]}loadScene(t){const e=this.extensions,n=this.json.scenes[t],i=this,s=new De;n.name&&(s.name=i.createUniqueName(n.name)),Xn(s,n),n.extensions&&Ai(e,s,n);const a=n.nodes||[],o=[];for(let l=0,c=a.length;l<c;l++)o.push(i.getDependency("node",a[l]));return Promise.all(o).then(function(l){for(let h=0,u=l.length;h<u;h++)s.add(l[h]);const c=h=>{const u=new Map;for(const[d,f]of i.associations)(d instanceof Tn||d instanceof Ce)&&u.set(d,f);return h.traverse(d=>{const f=i.associations.get(d);f!=null&&u.set(d,f)}),u};return i.associations=c(s),s})}_createAnimationTracks(t,e,n,i,s){const a=[],o=t.name?t.name:t.uuid,l=[];hi[s.path]===hi.weights?t.traverse(function(d){d.morphTargetInfluences&&l.push(d.name?d.name:d.uuid)}):l.push(o);let c;switch(hi[s.path]){case hi.weights:c=fs;break;case hi.rotation:c=ps;break;case hi.position:case hi.scale:c=ms;break;default:switch(n.itemSize){case 1:c=fs;break;case 2:case 3:default:c=ms;break}break}const h=i.interpolation!==void 0?My[i.interpolation]:js,u=this._getArrayFromAccessor(n);for(let d=0,f=l.length;d<f;d++){const m=new c(l[d]+"."+hi[s.path],e.array,u,h);i.interpolation==="CUBICSPLINE"&&this._createCubicSplineTrackInterpolant(m),a.push(m)}return a}_getArrayFromAccessor(t){let e=t.array;if(t.normalized){const n=Zo(e.constructor),i=new Float32Array(e.length);for(let s=0,a=e.length;s<a;s++)i[s]=e[s]*n;e=i}return e}_createCubicSplineTrackInterpolant(t){t.createInterpolant=function(n){const i=this instanceof ps?yy:qu;return new i(this.times,this.values,this.getValueSize()/3,n)},t.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline=!0}}function Cy(r,t,e){const n=t.attributes,i=new Qn;if(n.POSITION!==void 0){const o=e.json.accessors[n.POSITION],l=o.min,c=o.max;if(l!==void 0&&c!==void 0){if(i.set(new P(l[0],l[1],l[2]),new P(c[0],c[1],c[2])),o.normalized){const h=Zo(rs[o.componentType]);i.min.multiplyScalar(h),i.max.multiplyScalar(h)}}else{console.warn("THREE.GLTFLoader: Missing min/max properties for accessor POSITION.");return}}else return;const s=t.targets;if(s!==void 0){const o=new P,l=new P;for(let c=0,h=s.length;c<h;c++){const u=s[c];if(u.POSITION!==void 0){const d=e.json.accessors[u.POSITION],f=d.min,m=d.max;if(f!==void 0&&m!==void 0){if(l.setX(Math.max(Math.abs(f[0]),Math.abs(m[0]))),l.setY(Math.max(Math.abs(f[1]),Math.abs(m[1]))),l.setZ(Math.max(Math.abs(f[2]),Math.abs(m[2]))),d.normalized){const v=Zo(rs[d.componentType]);l.multiplyScalar(v)}o.max(l)}else console.warn("THREE.GLTFLoader: Missing min/max properties for accessor POSITION.")}}i.expandByVector(o)}r.boundingBox=i;const a=new Ln;i.getCenter(a.center),a.radius=i.min.distanceTo(i.max)/2,r.boundingSphere=a}function Rh(r,t,e){const n=t.attributes,i=[];function s(a,o){return e.getDependency("accessor",a).then(function(l){r.setAttribute(o,l)})}for(const a in n){const o=jo[a]||a.toLowerCase();o in r.attributes||i.push(s(n[a],o))}if(t.indices!==void 0&&!r.index){const a=e.getDependency("accessor",t.indices).then(function(o){r.setIndex(o)});i.push(a)}return Ht.workingColorSpace!==qe&&"COLOR_0"in n&&console.warn(`THREE.GLTFLoader: Converting vertex colors from "srgb-linear" to "${Ht.workingColorSpace}" not supported.`),Xn(r,t),Cy(r,t,e),Promise.all(i).then(function(){return t.targets!==void 0?Sy(r,t.targets,e):r})}const Kr=["torso","armL","armR","legL","legR","head"],Ch=["blue_bot","blue_bot_lo","red_grunt","red_grunt_lo","red_brute","red_brute_lo","boss_titan","boss_inferno","boss_void","cannon","turret","barrel"];function Py(r){for(let t=r;t;t=t.parent){const e=Kr.findIndex(n=>t.name===n||t.name.startsWith(n+"_"));if(e>=0&&Kr.includes(t.name))return{index:e,node:t};if(e>=0&&!t.parent?.name.startsWith(Kr[e]))return{index:e,node:t}}return{index:0,node:r}}class Ly{constructor(){this.scenes=new Map,this.bots=new Map,this.loadMs=0}async load(t,e){const n=performance.now(),i=new $x;let s=0;await Promise.all(Ch.map(async a=>{const o=await i.loadAsync(`${t}models/${a}.glb`);o.scene.updateMatrixWorld(!0),this.scenes.set(a,o.scene),e(++s/Ch.length)})),this.loadMs=performance.now()-n}model(t){const e=this.scenes.get(t);if(!e)throw new Error(`model not loaded: ${t}`);const n=e.clone(!0),i=new Map;return n.traverse(s=>{const a=s;if(!a.isMesh)return;const o=a.material;i.has(o)||i.set(o,o.clone()),a.material=i.get(o)}),n}bot(t){const e=this.bots.get(t);if(e)return e;const n=this.scenes.get(t);if(!n)throw new Error(`model not loaded: ${t}`);const i=[],s=Kr.map(()=>new P);n.traverse(l=>{const c=l;if(!c.isMesh)return;const h=Py(c);h.node.getWorldPosition(s[h.index]);const u=c.material,d=c.geometry.index?c.geometry.toNonIndexed():c.geometry.clone();d.applyMatrix4(c.matrixWorld);const f=d.attributes.position.count,m=new ye;m.setAttribute("position",d.attributes.position),m.setAttribute("normal",d.attributes.normal);const v=new Float32Array(f*3),g=new Float32Array(f),p=new Float32Array(f).fill(h.index),x=u.emissive&&u.emissive.r+u.emissive.g+u.emissive.b>.01;for(let y=0;y<f;y++)v[y*3]=u.color.r,v[y*3+1]=u.color.g,v[y*3+2]=u.color.b,g[y]=x?1:0;m.setAttribute("color",new ge(v,3)),m.setAttribute("aEmit",new ge(g,1)),m.setAttribute("aPart",new ge(p,1)),i.push(m)});const a=Hu(i,!1);a.computeBoundingSphere();const o={geometry:a,pivots:s,triangles:a.attributes.position.count/3};return this.bots.set(t,o),o}}const na=class na{constructor(t,e){this.step=t,this.render=e,this.raf=0,this.last=0,this.acc=0,this.running=!1,this.frameMs=16.7,this.tick=n=>{if(!this.running)return;this.raf=requestAnimationFrame(this.tick);const i=Math.min(.25,Math.max(0,(n-this.last)/1e3));this.last=n,this.frameMs+=(i*1e3-this.frameMs)*.1,this.acc+=i;let s=0;for(;this.acc>=ts&&s<na.MAX_STEPS;)this.step(ts),this.acc-=ts,s++;this.acc>ts&&(this.acc=0),this.render(i,this.acc/ts)}}start(){this.running||(this.running=!0,this.last=performance.now(),this.acc=0,this.raf=requestAnimationFrame(this.tick))}stop(){this.running=!1,cancelAnimationFrame(this.raf)}reset(){this.last=performance.now(),this.acc=0}};na.MAX_STEPS=4;let Jo=na;const Iy={titan:16747066,inferno:16734750,void:11561983};function Ph(){try{return window.localStorage}catch{return null}}class Dy{constructor(t,e){this.stage=t,this.onLoadProgress=e,this.assets=new Ly,this.audio=new u_,this.cameraCtl=new sx,this.env=null,this.gateView=null,this.obstacleView=null,this.telegraphView=null,this.bossView=null,this.cannonView=null,this.debugEl=null,this.screen="loading",this.returnTo="menu",this.input={aimX:0,ability:!1},this.keys=new Set,this.dragId=-1,this.dragStartX=0,this.dragStartAim=0,this.time=0,this.endTimer=0,this.lastSummary=null,this.lastReward=null,this.submitNote="",this.runSeq=0,this.sessionId="local",this.killsReported=0,this.analyticsT=0,this.bossFxT=0,this.hinted=!1,this.slowTick=0,this.mode="campaign",this.run={stage:0,score:0,kills:0,lost:0,time:0,peak:0,gates:0},this.continueOffer=null,this.paying=!1,this.shop=null,this.buying=!1,this.gatesSeen=new Set,this.v=new P,this.lastStats={drawCalls:0,triangles:0,geometries:0,textures:0,pixelRatio:1,width:1,height:1},this.canvas=D("canvas.game-canvas"),this.ui=D("div.ui"),t.append(this.canvas,this.ui),this.save=Fx(Ph()),this.loop=new Jo(n=>this.step(n),n=>this.render(n))}async init(){if(!Mh.supported())throw new Error("WebGL2 is not available on this device/browser.");this.onLoadProgress(.05,"Connecting"),this.adapter=await J_(),this.stage.classList.toggle("in-app",this.adapter.name==="hash-app"),this.fade=D("div.fade"),this.stage.append(this.fade),this.quality=new $o(this.save.settings.quality,(t,e)=>this.onQuality(t,e)),this.renderer=new Mh(this.canvas,this.quality.preset.antialias),this.lighting=new ux(this.renderer.scene),this.renderer.setBloom(this.quality.preset.bloom),await this.assets.load("./",t=>this.onLoadProgress(.1+t*.8,"Loading models")),this.onLoadProgress(.95,"Building world"),this.buildPersistentViews(),this.buildUi(),this.bindInput(),new ResizeObserver(()=>this.resize()).observe(this.stage),this.resize(),this.audio.setMusic(this.save.settings.music),this.audio.setSfx(this.save.settings.sfx),this.adapter.track("game_open",{adapter:this.adapter.name,quality:this.quality.level}),this.adapter.startSession().then(t=>this.sessionId=t.sessionId).catch(()=>{}),this.flushPending(),this.adapter.continueOffer().then(t=>this.continueOffer=t).catch(()=>{}),this.loadShop(),this.loadLevel(Ys(this.save.unlocked),!0),this.go("menu"),this.loop.start(),this.onLoadProgress(1,"Ready")}buildPersistentViews(){const t=this.quality.preset;this.effects?.group.removeFromParent(),this.crowdView?.group.removeFromParent(),this.crowdView?.dispose(),this.effects=new cx(t.particles),this.crowdView=new lx(this.assets,t,ir(this.save.skins.army)),this.renderer.scene.add(this.crowdView.group,this.effects.group)}onQuality(t,e){this.renderer&&(e&&(this.buildPersistentViews(),this.buildLevelViews()),this.resize(),this.renderer.setBloom(t.bloom))}resize(){const t=this.stage.getBoundingClientRect();t.width<2||t.height<2||(this.renderer.resize(t.width,t.height,this.quality.pixelRatio(window.devicePixelRatio||1)),this.cameraCtl.setAspect(t.width/t.height))}loadLevel(t,e,n={}){this.level=t;const i=X_(this.save.upgrades);this.sim=new D_(this.level,e?{...i,startArmy:Math.max(10,i.startArmy)}:i,n),this.input.aimX=0,this.input.ability=!1,this.effects.clear(),this.gatesSeen.clear(),this.killsReported=0,this.buildLevelViews(),this.cameraCtl.reset(),this.hud.reset()}buildLevelViews(){if(!this.sim)return;const t=this.renderer.scene;this.env?.dispose(),this.gateView?.dispose(),this.obstacleView?.dispose(),this.telegraphView?.dispose(),this.bossView?.dispose(),this.cannonView?.dispose(),this.env=new dx(this.level,this.quality.preset),this.lighting.apply(this.env.theme),this.gateView=new vx(this.sim.gates.gates),this.obstacleView=new xx(this.sim.obstacles.list,this.assets,this.env.theme.track),this.telegraphView=new Mx(this.sim.boss.telegraphs),this.bossView=new ex(this.sim.boss,this.assets),this.cannonView=new rx(this.sim.cannon,this.assets,ir(this.save.skins.cannon)),t.add(this.env.group,this.gateView.group,this.obstacleView.group,this.telegraphView.group,this.bossView.group,this.cannonView.group)}startLevel(t){this.mode="campaign";const e=Ys(Math.min(t,this.save.unlocked));this.begin(e,{},`LEVEL ${e.id}`,gs[e.world]),e.id===1&&!this.hinted&&(this.hud.showHint(!0),window.setTimeout(()=>this.hud.showHint(!1),6e3)),this.adapter.track("game_start",{level:e.id}),this.adapter.track("level_start",{level:e.id,world:e.world,boss:e.boss.kind})}startEndless(){this.save.unlocked<=Ko||(this.mode="endless",this.run={stage:0,score:0,kills:0,lost:0,time:0,peak:0,gates:0},this.adapter.track("game_start",{mode:"endless"}),this.startStage(1,{}))}startStage(t,e){this.run.stage=t;const n=z_(t);this.begin(n,e,`STAGE ${t}`,`Endless · ${gs[n.world]}`),this.adapter.track("level_start",{mode:"endless",stage:t,world:n.world,boss:n.boss.kind})}begin(t,e,n,i){this.audio.unlock(),this.loadLevel(t,!1,e),this.lastSummary=null,this.endTimer=0,this.runSeq++,this.audio.startMusic(this.level.world),this.fade.classList.remove("go"),this.fade.offsetWidth,this.fade.classList.add("go"),this.audio.setIntensity(0),this.go("playing"),this.loop.reset(),this.hud.intro(n,this.mode==="endless"?"Boss every stage · cannon health carries over":t.name,t.world,i,ta[t.boss.kind].name)}get title(){return this.mode==="endless"?`ENDLESS · STAGE ${this.run.stage}`:`LEVEL ${this.level.id} · ${this.level.name}`}replay(){this.mode==="endless"?this.startEndless():this.startLevel(this.level.id)}buildUi(){this.hud=new Ix(()=>this.pause(),()=>this.input.ability=!0),this.menu=new Gx({play:()=>this.startLevel(this.save.unlocked),endless:()=>this.startEndless(),skins:()=>this.open("skins"),levels:()=>this.go("levels"),upgrades:()=>this.open("upgrades"),leaderboard:()=>this.open("leaderboard"),settings:()=>this.open("settings")}),this.levels=new Nx(t=>this.startLevel(t),()=>this.go("menu")),this.pauseMenu=new Wx({resume:()=>this.resume(),restart:()=>this.replay(),settings:()=>this.open("settings"),quit:()=>this.quitToMenu()}),this.results=new Xx({next:()=>this.startLevel(Math.min(en,this.level.id+1)),retry:()=>this.replay(),upgrades:()=>this.open("upgrades"),menu:()=>this.quitToMenu()}),this.upgrades=new Kx(t=>void this.buy(t),()=>this.go(this.returnTo)),this.settings=new qx(t=>this.applySettings(t),()=>this.go(this.returnTo),()=>this.infoLine()),this.board=new Dx(()=>this.go(this.returnTo)),this.continueScreen=new G_({pay:()=>void this.payContinue(),decline:()=>this.declineContinue()}),this.skinScreen=new V_((t,e)=>void this.pickSkin(t,e),()=>this.go(this.returnTo)),this.screens={menu:this.menu,levels:this.levels,paused:this.pauseMenu,won:this.results,lost:this.results,upgrades:this.upgrades,settings:this.settings,leaderboard:this.board,skins:this.skinScreen,continue:this.continueScreen},this.ui.append(this.hud.el,this.menu.el,this.levels.el,this.pauseMenu.el,this.results.el,this.upgrades.el,this.settings.el,this.board.el,this.skinScreen.el,this.continueScreen.el),new URLSearchParams(location.search).has("debug")&&(this.debugEl=D("pre.debug"),this.ui.append(this.debugEl)),this.ui.addEventListener("click",t=>{t.target.closest("button")&&(this.audio.unlock(),this.audio.play("click"))})}open(t){this.returnTo=this.screen==="settings"||this.screen==="upgrades"||this.screen==="leaderboard"||this.screen==="skins"?this.returnTo:this.screen,this.go(t)}go(t){this.screen=t;for(const e of Object.keys(this.screens))this.screens[e].el.classList.remove("show");switch(t!=="playing"&&t!=="loading"&&this.screens[t].el.classList.add("show"),this.hud.show(t==="playing"||t==="paused"||t==="continue"),t){case"menu":this.menu.refresh(this.save,this.shop);break;case"levels":this.levels.refresh(this.save);break;case"paused":this.pauseMenu.refresh({title:this.title,progress:this.sim.progress,army:this.sim.crowd.count,score:(this.mode==="endless"?this.run.score:0)+this.sim.score()});break;case"upgrades":this.upgrades.refresh(this.save,this.shop),this.loadShop();break;case"skins":this.skinScreen.refresh(this.save,this.shop),this.loadShop();break;case"settings":this.settings.refresh(this.save.settings);break;case"leaderboard":this.showLeaderboard();break;case"won":case"lost":this.lastSummary&&this.lastReward&&this.results.show(this.lastSummary,this.lastReward,this.mode==="campaign"&&this.level.id<en,this.submitNote,this.sim.progress,this.mode==="endless"?this.run.stage:0);break}}pause(){this.screen!=="playing"||this.sim.status!=="playing"||(this.go("paused"),this.audio.suspend())}resume(){this.screen==="paused"&&(this.audio.resume(),this.go("playing"),this.loop.reset())}quitToMenu(){this.audio.resume(),this.audio.stopMusic(),this.sim.status==="playing"&&(this.screen==="paused"||this.screen==="playing")&&this.adapter.track("game_exit",{level:this.level.id,progress:Number(this.sim.progress.toFixed(2))}),this.mode==="endless"&&this.sim.status==="playing"&&this.run.score>0&&(Sh(this.save,this.run.score,this.run.stage-1),this.persist()),this.mode="campaign",this.loadLevel(Ys(this.save.unlocked),!0),this.go("menu")}async loadShop(){try{this.shop=await this.adapter.shopCatalog()}catch{return}this.shop?.owned&&Vx(this.save,this.shop.owned)&&this.persist(),this.refreshShopViews()}refreshShopViews(){this.screen==="upgrades"?this.upgrades.refresh(this.save,this.shop):this.screen==="skins"?this.skinScreen.refresh(this.save,this.shop):this.screen==="menu"&&this.menu.refresh(this.save,this.shop)}async purchase(t){if(this.buying)return!1;this.buying=!0;try{const e=await this.adapter.buyItem(t);return this.shop&&e.balance!=null&&(this.shop.balance=e.balance),e.ok}catch{return!1}finally{this.buying=!1}}async pickSkin(t,e){let n="click";zx(this.save,t,e)||(await this.purchase({kind:"skin",slot:t,id:e})?(Hx(this.save,t,e),n="buy"):n="deny"),this.audio.play(n),Wu(this.save,t,e)&&(this.persist(),this.buildPersistentViews(),this.buildLevelViews()),this.refreshShopViews()}async buy(t){const e=this.save.upgrades[t];e<_i[t].maxLevel&&await this.purchase({kind:"upgrade",id:t,level:e})&&Bx(this.save,t)?(this.audio.play("buy"),this.adapter.track("upgrade_purchased",{upgrade:t,level:this.save.upgrades[t]}),this.persist()):this.audio.play("deny"),this.refreshShopViews()}applySettings(t){this.save.settings=t,this.audio.unlock(),this.audio.setMusic(t.music),this.audio.setSfx(t.sfx),this.quality.set(t.quality),this.persist()}persist(){Ox(Ph(),this.save)}infoLine(){const t=this.lastStats;return`Quality: ${this.quality.level} · ${t.width}×${t.height} @${t.pixelRatio.toFixed(2)}x · host: ${this.adapter.name}`}async showLeaderboard(){this.board.loading();const t=Yr(this.save);try{this.adapter.setLocalBest?.(t);const[n,i]=await Promise.all([this.adapter.getLeaderboard(20),this.adapter.getRewardEligibility()]);if(this.screen!=="leaderboard")return;n?this.board.show(n,t,`${this.adapter.name==="mock"?"Sample data (offline mock). ":""}${i.description??""}`):this.board.show(null,t,"Live rankings are shown in Hash Arcade’s leaderboard. Your career score is submitted after every win.")}catch{this.screen==="leaderboard"&&this.board.show(null,t,"Could not reach the leaderboard. Check your connection and try again.",!0)}}bindInput(){const t=this.stage,e=s=>{this.audio.unlock(),!(this.screen!=="playing"||s.target.closest("button"))&&(this.dragId=s.pointerId,this.dragStartX=s.clientX,this.dragStartAim=this.input.aimX,this.hinted||(this.hinted=!0,this.hud.showHint(!1)))},n=s=>{if(this.screen!=="playing")return;const a=t.getBoundingClientRect();if(s.pointerId===this.dragId){const o=(s.clientX-this.dragStartX)/a.width;this.input.aimX=Math.max(-qt,Math.min(qt,this.dragStartAim+o*qt*3.4))}else s.pointerType==="mouse"&&this.dragId<0&&s.buttons===0&&(this.input.aimX=((s.clientX-a.left)/a.width-.5)*qt*2.5)},i=s=>{s.pointerId===this.dragId&&(this.dragId=-1)};t.addEventListener("pointerdown",e),window.addEventListener("pointermove",n),window.addEventListener("pointerup",i),window.addEventListener("pointercancel",i),t.addEventListener("contextmenu",s=>s.preventDefault()),window.addEventListener("keydown",s=>{s.repeat||(this.keys.add(s.code),(s.code==="Escape"||s.code==="KeyP")&&(this.screen==="playing"?this.pause():this.screen==="paused"&&this.resume()),(s.code==="Space"||s.code==="KeyE")&&this.screen==="playing"&&(this.input.ability=!0,s.preventDefault()),(s.code==="Enter"||s.code==="Space")&&this.screen==="menu"&&this.startLevel(this.save.unlocked))}),window.addEventListener("keyup",s=>this.keys.delete(s.code)),window.addEventListener("blur",()=>{this.keys.clear(),this.dragId=-1}),document.addEventListener("visibilitychange",()=>{document.hidden?(this.screen==="playing"&&this.pause(),this.audio.suspend(),this.loop.stop()):(this.screen!=="paused"&&this.audio.resume(),this.loop.start())}),window.addEventListener("pagehide",()=>{(this.screen==="playing"||this.screen==="paused")&&this.adapter.track("game_exit",{level:this.level.id})})}step(t){if(this.screen!=="playing")return;const e=this.keys.has("ArrowLeft")||this.keys.has("KeyA"),n=this.keys.has("ArrowRight")||this.keys.has("KeyD");if(e!==n&&(this.input.aimX=Math.max(-qt,Math.min(qt,this.input.aimX+(n?1:-1)*11*t)),this.hinted||(this.hinted=!0,this.hud.showHint(!1))),this.sim.status==="playing"){if(this.sim.boss.state===Jt.Dying&&++this.slowTick%3!==0)return;this.sim.step(this.input,t),this.input.ability=!1,this.presentFx(),this.sim.fx.clear();const i=this.sim.status;i==="lost"&&this.continueOffer&&this.sim.continues===0?(this.audio.play("defeat"),this.audio.setIntensity(0),this.continueScreen.show(this.continueOffer),this.go("continue")):i!=="playing"&&this.finish()}else if(this.endTimer>0){if(this.endTimer-=t,this.endTimer>0)return;this.mode==="endless"&&this.sim.status==="won"?this.startStage(this.run.stage+1,{startHp:this.sim.cannon.hp+k_,extraArmy:Math.min(O_,this.sim.crowd.count)}):this.go(this.sim.status==="won"?"won":"lost")}}async payContinue(){if(this.paying||this.screen!=="continue")return;this.paying=!0,this.continueScreen.busy();let t=!1;try{t=await this.adapter.payContinue()}catch{t=!1}if(this.paying=!1,this.screen==="continue"){if(!t){this.continueScreen.failed();return}this.sim.revive(),this.presentFx(),this.sim.fx.clear(),this.adapter.track("game_start",{level:this.level.id,continued:!0}),this.hud.announce("BACK IN THE FIGHT","good",1500),this.go("playing"),this.loop.reset()}}declineContinue(){this.paying||this.screen!=="continue"||(this.continueScreen.stop(),this.finish(),this.endTimer=0,this.go("lost"))}finishStage(t){const e=this.run,n=t.status==="won";if(e.score+=t.score,e.kills+=t.enemiesKilled,e.lost+=t.unitsLost,e.time+=t.time,e.gates+=t.gateActivations,e.peak=Math.max(e.peak,t.peakArmy),this.audio.setIntensity(0),this.audio.stopMusic(),this.audio.play(n?"victory":"defeat"),this.haptic(n?"medium":"heavy"),this.reportKills(),this.adapter.track(n?"level_complete":"level_failed",{mode:"endless",stage:e.stage,score:e.score}),n){this.endTimer=2.2;return}const i={levelId:0,status:"lost",score:e.score,time:e.time,enemiesKilled:e.kills,unitsLost:e.lost,peakArmy:e.peak,armyLeft:0,gateActivations:e.gates,cannonHp:0,stars:0};this.lastSummary=i,this.lastReward={newBest:Sh(this.save,e.score,e.stage),unlockedLevel:null},this.submitNote="",this.persist(),this.endTimer=1.3,this.submit(i)}finish(){const t=this.sim.summary();if(this.mode==="endless"){this.finishStage(t);return}const e=t.status==="won";this.lastSummary=t,this.lastReward=kx(this.save,this.level,t),this.submitNote="",this.persist(),this.endTimer=e?2.4:1.3,this.audio.setIntensity(0),this.audio.stopMusic(),this.audio.play(e?"victory":"defeat"),this.haptic(e?"medium":"heavy"),this.reportKills();const n={level:this.level.id,score:t.score,time:Math.round(t.time),peak_army:t.peakArmy,units_lost:t.unitsLost};this.adapter.track(e?"level_complete":"level_failed",e?{...n,stars:t.stars}:{...n,progress:Number(this.sim.progress.toFixed(2))}),e&&this.submit(t)}async submit(t){const e={runId:`${this.sessionId}-${this.runSeq}-${Date.now().toString(36)}`,score:Yr(this.save),level:t.levelId,levelScore:t.score,stars:t.stars,durationMs:Math.round(t.time*1e3),proof:{enemiesKilled:t.enemiesKilled,peakArmy:t.peakArmy,gateActivations:t.gateActivations,unitsLost:t.unitsLost}};try{const n=await this.adapter.submitScore(e);!n.accepted&&n.message&&(this.submitNote=n.message)}catch{this.save.pending.push({runId:e.runId,score:e.score,level:e.level}),this.save.pending=this.save.pending.slice(-10),this.persist(),this.submitNote="Offline — your score is saved and will be sent next time."}(this.screen==="won"||this.screen==="lost")&&this.lastSummary&&this.lastReward&&this.results.show(this.lastSummary,this.lastReward,this.mode==="campaign"&&this.level.id<en,this.submitNote,this.sim.progress,this.mode==="endless"?this.run.stage:0)}async flushPending(){const t=this.save.pending;if(t.length===0)return;const e=t[t.length-1];try{await this.adapter.submitScore({runId:e.runId,score:Math.max(e.score,Yr(this.save)),level:e.level,levelScore:0,stars:0,durationMs:0,proof:{enemiesKilled:0,peakArmy:0,gateActivations:0,unitsLost:0}}),this.save.pending=[],this.persist()}catch{}}reportKills(){const t=this.sim.enemies.killed-this.killsReported;t>0&&this.adapter.track("enemy_defeated",{level:this.level.id,count:t}),this.killsReported=this.sim.enemies.killed}haptic(t){this.save.settings.haptics&&this.adapter.haptic(t)}toScreen(t,e,n){const i=this.stage.getBoundingClientRect();return this.v.set(t,e,-n).project(this.cameraCtl.camera),{x:(this.v.x*.5+.5)*i.width,y:(-this.v.y*.5+.5)*i.height}}presentFx(){const t=this.sim.fx,e=this.effects,n=this.audio,i=this.quality.level==="low",s=i?.5:1;for(let a=0;a<t.n;a++){const o=t.x[a],l=-t.z[a],c=t.a[a];switch(t.type[a]){case xt.Muzzle:n.play("shoot",this.sim.cannon.overdrive>0?1.25:1),e.burst(o,1.25,l,3*s,10481663,3,.18,.22,0,.3);break;case xt.PodLand:n.play("deploy"),e.ring(o,l,5232895,.9,.3),e.burst(o,.3,l,4*s,7331071,2.5,.3,.16,4);break;case xt.PodHit:n.play("hit"),e.burst(o,1,l,8*s,12580095,6,.3,.2,6);break;case xt.UnitDie:n.play("unitDie"),e.burst(o,.6,l,(c?7:3)*s,3111935,4.5,.5,.14,12,.9,!0);break;case xt.UnitFall:n.play("unitDie",.6);break;case xt.EnemyHit:n.play("hit",.8),e.burst(o,.8,l,2*s,16756858,4,.22,.14,8);break;case xt.EnemyDie:{n.play("enemyDie",c===2?.5:c===1?.75:1);const h=c===2;e.burst(o,.7,l,(h?30:9)*s,14689310,h?10:6.5,.7,h?.3:.19,13,1.2,!0),e.burst(o,.8,l,(h?14:4)*s,16753466,5,.35,.3,2),(h||c===3)&&(e.ring(o,l,16738858,3.2,.5),this.cameraCtl.shake(.35));break}case xt.GateAdd:case xt.GateMul:{const h=t.type[a]===xt.GateMul;n.play(c>=40?"gateBig":"gate",h?1.15:1),e.burst(o,1.4,l,Math.min(26,6+c/4)*s,h?10320895:6160304,6,.55,.2,5,1),e.ring(o,l,h?10320895:6160304,2.4,.4);const u=this.toScreen(o,3.6,-l);this.hud.float(`+${Math.round(c)}`,u.x,u.y,h?"#c4b0ff":"#8dffc8",c>=40),c>=40&&this.haptic("light");break}case xt.GateLoss:{n.play("deny"),n.play("unitDie",.7),e.ring(o,l,16726843,2.6,.4);const h=this.toScreen(o,3.6,-l);this.hud.float(`−${Math.round(c)}`,h.x,h.y,"#ff6b6b",c>=20),c>=20&&this.haptic("medium");break}case xt.GateCapped:{const h=this.toScreen(o,4.4,-l);this.hud.float("ARMY MAX",h.x,h.y,"#ffd23a",!0);break}case xt.Explosion:n.play("explosion"),e.burst(o,.8,l,40*s,16747050,11,.7,.36,6,1),e.burst(o,.8,l,16*s,3813424,7,.9,.24,12,1,!0),e.ring(o,l,16756810,Math.max(2,c),.5),this.cameraCtl.shake(.55),this.haptic("medium");break;case xt.BossHit:e.burst(o,2.5,l,5*s,16773296,6,.3,.2,6);break;case xt.BossAttack:n.play("bossAttack"),n.play("warning");break;case xt.BossIntro:n.play("bossRoar"),n.setIntensity(1),this.hud.bossWarning(ta[this.level.boss.kind].name),this.cameraCtl.shake(.5),this.haptic("heavy");break;case xt.BossDie:n.play("bossDie"),this.cameraCtl.shake(1),this.haptic("heavy"),this.adapter.track("boss_defeated",{level:this.level.id,boss:this.level.boss.kind,time:Math.round(this.sim.time)});break;case xt.CannonHit:n.play("cannonHit"),this.cameraCtl.shake(.4),this.hud.damageFlash(),this.haptic("medium"),e.burst(o,1,l,10*s,16734778,6,.4,.22,8);break;case xt.Impact:n.play("explosion",1.6),e.burst(o,.3,l,12*s,16761466,6,.4,.22,9),e.ring(o,l,16742970,1.8,.35),this.cameraCtl.shake(.2);break;case xt.Collapse:n.play("explosion",.7),e.burst(o,.2,l,24*s,5593702,6,.9,.3,14,.8,!0),this.cameraCtl.shake(.3);break;case xt.TurretShot:n.play("shoot",.55),e.burst(o,1.2,l,4*s,16738890,3,.2,.2,0);break;case xt.Ability:n.play("ability"),this.hud.announce("OVERDRIVE!","good",1200),e.ring(o,l,16765498,4,.5),this.haptic("light");break;case xt.BossShield:e.ring(o,l,11561983,6,.6,1.5),c===0?e.burst(o,4,l,30*s,13081599,9,.6,.3,4):this.hud.announce("SHIELD UP — BREAK IT","danger",1500);break;case xt.Summon:e.ring(o,l,16726586,5,.6);break;case xt.Victory:e.confetti(o,3,l-6,i?60:160);break}}for(const a of this.sim.gates.gates)a.activations>0&&!this.gatesSeen.has(a.def.z*100+a.def.x)&&(this.gatesSeen.add(a.def.z*100+a.def.x),this.adapter.track("gate_activated",{level:this.level.id,gate:Du(a.def.op)}));this.analyticsT+=1,this.analyticsT>=300&&(this.analyticsT=0,this.reportKills())}render(t){const e=this.screen==="paused";e||(this.time+=t,zu.value=this.time);const n=this.sim,i=this.screen!=="playing"&&this.screen!=="paused"&&this.screen!=="won"&&this.screen!=="lost"&&this.screen!=="continue";this.cameraCtl.lookDrop=this.screen==="skins"?3.4:0,this.cameraCtl.update(e?0:t,n,this.time,i);const s=this.cameraCtl.camera;this.crowdView.update(n),this.cannonView.update(this.time,e?0:t,s),this.gateView.update(this.time,i?-999:n.cannon.z),this.obstacleView.update(this.time),this.telegraphView.update(),this.bossView.update(this.time),this.env.update(this.time,t,s.position),e||(this.ambientFx(t),this.effects.update(t)),this.renderer.render(s),(this.screen==="playing"||this.screen==="paused")&&this.updateHud(),this.screen==="playing"&&this.quality.sample(t*1e3),this.lastStats=this.renderer.stats(),this.debugEl&&this.updateDebug()}ambientFx(t){const e=this.sim,n=this.effects;if(this.quality.level!=="low")for(let l=0;l<e.pods.cap;l++)e.pods.live[l]&&n.puff(e.pods.x[l],1.3,-e.pods.z[l],8381695,.22,.25,.2);const i=e.boss;if(this.bossFxT-=t,this.bossFxT>0)return;this.bossFxT=.12;const s=i.x,a=-i.z,o=Iy[i.kind];if(i.state===Jt.Dying)n.burst(s+(Math.random()-.5)*4,1+Math.random()*5,a+(Math.random()-.5)*3,18,16753466,9,.6,.34,6),n.burst(s,3,a,6,3355708,8,.9,.26,12,1,!0),this.cameraCtl.shake(.25);else if(i.state===Jt.Fight||i.state===Jt.Intro)if(i.kind==="inferno")for(let l=0;l<3;l++)n.puff(s+(Math.random()-.5)*3,5.6,a-.6,16747050,.5,.9,3);else i.kind==="void"?n.puff(s+(Math.random()-.5)*4,2+Math.random()*5,a,o,.3,.7,1):i.attackT>1.1&&i.attackT<1.3&&n.burst(s,.3,a+2.5,14,12166282,5,.6,.3,8,.6,!0)}updateHud(){const t=this.sim,e=t.boss,n=e.state===Jt.Intro||e.state===Jt.Fight||e.state===Jt.Dying;this.hud.update({title:this.title,progress:t.progress,army:t.crowd.count,atCap:t.crowd.count>=er,score:(this.mode==="endless"?this.run.score:0)+t.score(),cannonHp:t.cannon.hp/t.cannon.maxHp,bossName:n?e.stats.name:null,bossHp:e.hp/e.maxHp,bossShield:e.shield>0?e.shield/Math.max(1,e.shieldMax):0,abilityCooldown:t.cannon.abilityCd/t.stats.abilityCooldown,abilityActive:t.cannon.overdrive>0})}updateDebug(){const t=this.lastStats,e=performance.memory;this.debugEl.textContent=`${(1e3/this.loop.frameMs).toFixed(0)} fps  ${this.loop.frameMs.toFixed(1)} ms
draws ${t.drawCalls}  tris ${(t.triangles/1e3).toFixed(0)}k
geo ${t.geometries}  tex ${t.textures}
units ${this.sim.crowd.count} (${this.sim.crowd.alive} agents)
enemies ${this.sim.enemies.alive}  inst ${this.crowdView.drawn}
particles ${this.effects.activeParticles}
q ${this.quality.level} x${this.quality.scale.toFixed(2)} pr ${t.pixelRatio.toFixed(2)}
${t.width}x${t.height}  load ${this.assets.loadMs.toFixed(0)} ms`+(e?`
heap ${(e.usedJSHeapSize/1048576).toFixed(0)} MB`:"")}get debug(){return{sim:()=>this.sim,save:()=>this.save,adapter:()=>this.adapter,stats:()=>({...this.lastStats,frameMs:this.loop.frameMs,quality:this.quality.level,scale:this.quality.scale,loadMs:this.assets.loadMs,particles:this.effects.activeParticles,instances:this.crowdView.drawn}),input:this.input,advance:t=>{for(let e=0;e<t*60;e++)this.step(1/60);this.cameraCtl.reset()},unlockAll:()=>{this.save.unlocked=en}}}}const Ny=document.getElementById("boot"),Uy=document.getElementById("boot-fill"),Qo=document.getElementById("boot-label"),Fy=document.getElementById("stage"),Yu=new Dy(Fy,(r,t)=>{Uy.style.transform=`scaleX(${Math.max(.02,r).toFixed(3)})`,Qo.textContent=t.toUpperCase()});Yu.init().then(()=>Ny.classList.add("done")).catch(r=>{console.error(r),Qo.className="err",Qo.textContent=r instanceof Error?r.message:"HASH RUSH could not start."});window.__hashRush=Yu;export{nr as S,Bu as U,_i as a,Oy as u};
