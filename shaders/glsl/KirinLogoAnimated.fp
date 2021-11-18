// ah shit here we go again

#define overlay(a,b) (a<0.5)?(2.0*a*b):(1.0-(2.0*(1.0-a)*(1.0-b)))
#define hardlight(a,b) (2*a<1.0)?clamp(2.0*a*b,0.0,1.0):clamp(1.0-2.0*(1.0-b)*(1.0-a),0.0,1.0)
const float pi = 3.14159265358979323846;

vec2 warpcoord( in vec2 uv )
{
	vec2 offset = vec2(0,0);
	offset.x = sin(pi*2.*(uv.x*8.+timer*.5))*.01;
	offset.y += timer*.25;
	offset.x = cos(pi*2.*(uv.y*4.+timer*.5))*.01;
	return fract(uv+offset);
}

vec2 warpcoord2( in vec2 uv )
{
	vec2 offset = vec2(0,0);
	offset.y = sin(pi*2.*(uv.x*4.+timer*.25))*.01;
	offset.x = cos(pi*2.*(uv.y*2.+timer*.25))*.01;
	return fract(uv+offset);
}

vec4 BilinearSampleNoWrap( in sampler2D tex, in vec2 pos, in vec2 size, in vec2 pxsize )
{
	vec2 f = fract(pos*size);
	pos += (.5-f)*pxsize;
	vec4 p0q0 = texture(tex,pos);
	vec4 p1q0 = texture(tex,pos+vec2(pxsize.x,0));
	vec4 p0q1 = texture(tex,pos+vec2(0,pxsize.y));
	vec4 p1q1 = texture(tex,pos+vec2(pxsize.x,pxsize.y));
	vec4 pInterp_q0 = mix(p0q0,p1q0,f.x);
	vec4 pInterp_q1 = mix(p0q1,p1q1,f.x);
	return mix(pInterp_q0,pInterp_q1,f.y);
}

vec4 BilinearSample( in sampler2D tex, in vec2 pos, in vec2 size, in vec2 pxsize )
{
	vec2 disp = floor(pos*vec2(2.,4.))/vec2(2.,4.);
	vec2 f = fract(pos*size);
	pos += (.5-f)*pxsize;
	vec4 p0q0 = texture(tex,fract((pos*vec2(2.,4.)))/vec2(2.,4.)+disp);
	vec4 p1q0 = texture(tex,fract((pos+vec2(pxsize.x,0))*vec2(2.,4.))/vec2(2.,4.)+disp);
	vec4 p0q1 = texture(tex,fract((pos+vec2(0,pxsize.y))*vec2(2.,4.))/vec2(2.,4.)+disp);
	vec4 p1q1 = texture(tex,fract((pos+vec2(pxsize.x,pxsize.y))*vec2(2.,4.))/vec2(2.,4.)+disp);
	vec4 pInterp_q0 = mix(p0q0,p1q0,f.x);
	vec4 pInterp_q1 = mix(p0q1,p1q1,f.x);
	return mix(pInterp_q0,pInterp_q1,f.y);
}

// based on gimp color to alpha, but simplified
vec4 blacktoalpha( in vec4 src )
{
	vec4 dst = src;
	float dist = 0., alpha = 0.;
	float d, a;
	a = clamp(dst.r,0.,1.);
	if ( a > alpha )
	{
		alpha = a;
		dist = d;
	}
	a = clamp(dst.g,0.,1.);
	if ( a > alpha )
	{
		alpha = a;
		dist = d;
	}
	a = clamp(dst.b,0.,1.);
	if ( a > alpha )
	{
		alpha = a;
		dist = d;
	}
	if ( alpha > 0. )
	{
		float ainv = 1./alpha;
		dst.rgb *= ainv;
	}
	dst.a *= alpha;
	return dst;
}

void SetupMaterial( inout Material mat )
{
	// store these to save some time
	vec2 size = vec2(textureSize(LogoTex,0));
	vec2 pxsize = 1./size;
	// y'all ready for this multilayered madness?
	vec2 uv = vTexCoord.st;
	// copy
	vec4 base = BilinearSample(LogoTex,warpcoord2(uv)*vec2(.5,.25),size,pxsize);
	// hard light
	vec4 tmp = BilinearSampleNoWrap(LogoTex,uv*vec2(.5,.25)+vec2(0.,.25),size,pxsize);
	base.r = hardlight(tmp.r,base.r);
	base.g = hardlight(tmp.g,base.g);
	base.b = hardlight(tmp.b,base.b);
	// add
	tmp = BilinearSampleNoWrap(LogoTex,uv*vec2(.5,.25)+vec2(0.,.5),size,pxsize);
	base.rgb += tmp.rgb;
	// color to alpha
	base = blacktoalpha(base);
	// separate layer
	tmp = BilinearSample(LogoTex,warpcoord(uv)*vec2(.5,.25)+vec2(0.,.75),size,pxsize);
	// overlay
	vec4 tmp2 = BilinearSampleNoWrap(LogoTex,uv*vec2(.5,.25)+vec2(.5,0.),size,pxsize);
	tmp.r = overlay(tmp.r,tmp2.r);
	tmp.g = overlay(tmp.g,tmp2.g);
	tmp.b = overlay(tmp.b,tmp2.b);
	// add
	tmp2 = BilinearSampleNoWrap(LogoTex,uv*vec2(.5,.25)+vec2(.5,.25),size,pxsize);
	tmp.rgb += tmp2.rgb;
	// alpha mask
	tmp.a = BilinearSampleNoWrap(LogoTex,uv*vec2(.5,.25)+vec2(.5,.5),size,pxsize).x;
	tmp.rgb *= tmp.a;
	// alpha blend
	tmp2 = BilinearSampleNoWrap(LogoTex,uv*vec2(.5,.25)+vec2(.5,.75),size,pxsize);
	vec4 tmp3;
	tmp3.a = tmp2.a+tmp.a*(1.-tmp2.a);
	tmp3.rgb = (tmp2.rgb*tmp2.a+tmp.rgb*tmp.a*(1.-tmp2.a))/tmp3.a;
	if ( tmp3.a == 0. ) tmp3.rgb = vec3(0.);
	// alpha blend back onto base layer
	tmp.a = tmp3.a+base.a*(1.-tmp3.a);
	tmp.rgb = (tmp3.rgb*tmp3.a+base.rgb*base.a*(1.-tmp3.a))/tmp.a;
	if ( tmp.a == 0. ) tmp.rgb = vec3(0.);
	base = tmp;
	// clamp borders
	vec2 sz = vec2(2048.,1024.);
	vec2 px = uv*sz;
	if ( (px.x <= 1) || (px.x >= (sz.x-1)) || (px.y <= 1) || (px.y >= (sz.y-1)) )
		base = vec4(0.);
	// ding, logo's done
	mat.Base = base;
	mat.Normal = ApplyNormalMap(vTexCoord.st);
}
