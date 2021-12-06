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

// based on gimp color to alpha, but simplified
vec4 blacktoalpha( in vec4 src )
{
	vec4 dst = src;
	float alpha = 0.;
	float a;
	a = clamp(dst.r,0.,1.);
	if ( a > alpha ) alpha = a;
	a = clamp(dst.g,0.,1.);
	if ( a > alpha ) alpha = a;
	a = clamp(dst.b,0.,1.);
	if ( a > alpha ) alpha = a;
	if ( alpha > 0. )
	{
		float ainv = 1./alpha;
		dst.rgb *= ainv;
	}
	dst.a *= alpha;
	return dst;
}
#ifdef NO_BILINEAR
#define BilinearSample(x,y,z,w) texture(x,y)
#else
vec4 BilinearSample( in sampler2D tex, in vec2 pos, in vec2 size, in vec2 pxsize )
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
#endif

void SetupMaterial( inout Material mat )
{
	// store these to save some time
	vec2 size = vec2(textureSize(Layer1,0));
	vec2 pxsize = 1./size;
	// y'all ready for this multilayered madness?
	vec2 uv = vTexCoord.st;
	// layer 1 base
	vec4 base = BilinearSample(Layer1,warpcoord2(uv),size,pxsize);
	// layer 2 hard light
	vec4 tmp = BilinearSample(Layer2,uv,size,pxsize);
	base.r = hardlight(tmp.r,base.r);
	base.g = hardlight(tmp.g,base.g);
	base.b = hardlight(tmp.b,base.b);
	// layer 3 add
	tmp = BilinearSample(Layer3,uv,size,pxsize);
	base.rgb += tmp.rgb;
	// black to alpha
	base = blacktoalpha(base);
	// separate layer 4
	tmp = BilinearSample(Layer4,warpcoord(uv),size,pxsize);
	// overlay layer 5 red
	vec4 tmp2;
	tmp2.r = BilinearSample(Layer5,uv,size,pxsize).r;
	tmp.r = overlay(tmp.r,tmp2.r);
	tmp.g = overlay(tmp.g,tmp2.r);
	tmp.b = overlay(tmp.b,tmp2.r);
	// add layer 6
	tmp2 = BilinearSample(Layer6,uv,size,pxsize);
	tmp.rgb += tmp2.rgb;
	// alpha mask layer 5 green
	tmp.a = BilinearSample(Layer5,uv,size,pxsize).g;
	tmp.rgb *= tmp.a;
	// alpha blend layer 7
	tmp2 = BilinearSample(Layer7,uv,size,pxsize);
	vec4 tmp3;
	tmp3.a = tmp2.a+tmp.a*(1.-tmp2.a);
	tmp3.rgb = (tmp2.rgb*tmp2.a+tmp.rgb*tmp.a*(1.-tmp2.a))/tmp3.a;
	if ( tmp3.a == 0. ) tmp3.rgb = vec3(0.);
	// blend onto base
	tmp.a = tmp3.a+base.a*(1.-tmp3.a);
	tmp.rgb = (tmp3.rgb*tmp3.a+base.rgb*base.a*(1.-tmp3.a))/tmp.a;
	if ( tmp.a == 0. ) tmp.rgb = vec3(0.);
	base = tmp;
	// clamp
	base = clamp(base,0.,1.);
	// ding, logo's done
	mat.Base = base;
}
