// background smoke with light influence

#define PI 3.14159265

void main()
{
	vec2 uv = TexCoord.st;
	vec4 res = texture(InputTexture,uv);
	vec3 base = res.rgb;
	vec2 bresl = textureSize(InputTexture,0);
	vec2 bof = 1./bresl;
	vec2 sr = vec2(1.,bof.x/bof.y)*.5;
	int rsamples, tstep = 1;
	vec2 bstr = bof*4.;
	float bstep;
	vec2 rcoord;
	for ( int i=1; i<=7; i++ )
	{
		rsamples = i*3;
		for ( int j=0; j<rsamples; j++ )
		{
			bstep = PI*2./rsamples;
			rcoord = vec2(cos(j*bstep),sin(j*bstep))*i;
			tstep++;
			base.rgb += texture(InputTexture,uv+rcoord*bstr).rgb;
		}
	}
	base /= tstep;
	base = pow(base,vec3(.6,.8,2.));
	vec2 lresl = textureSize(glowtex,0);
	float ar = bresl.x/bresl.y;
	float sar = lresl.x/lresl.y;
	uv = TexCoord-vec2(.5);
	uv.x *= ar/sar;
	uv = clamp(-uv*.75+vec2(.5),0.,1.);
	base += texture(glowtex,uv).rgb*clamp(timer-20.,0.,10.)*.05;
	uv = (TexCoord.st+vec2(1.,0.))*sr;
	float ang = timer*.05;
	vec2 uv2 = vec2(uv.x*cos(ang)-uv.y*sin(ang),uv.y*cos(ang)+uv.x*sin(ang))*1.3;
	vec3 col = texture(smoketex,uv2).rgb;
	uv = (TexCoord.st+vec2(1.,2.))*sr;
	ang = timer*.03;
	uv2 = vec2(uv.x*cos(ang)-uv.y*sin(ang),uv.y*cos(ang)+uv.x*sin(ang))*1.5;
	col += texture(smoketex,uv2).rgb;
	uv = (TexCoord.st+vec2(-1.,1.))*sr;
	ang = timer*.04;
	uv2 = vec2(uv.x*cos(ang)-uv.y*sin(ang),uv.y*cos(ang)+uv.x*sin(ang))*1.6;
	col += texture(smoketex,uv2).rgb;
	uv = (TexCoord.st+vec2(-2.,3.))*sr;
	ang = timer*.02;
	uv2 = vec2(uv.x*cos(ang)-uv.y*sin(ang),uv.y*cos(ang)+uv.x*sin(ang))*1.2;
	col += texture(smoketex,uv2).rgb;
	col *= .25;
	col *= base+vec3(.3,.1,.08);
	FragColor = vec4(res.rgb+col,1.);
}
