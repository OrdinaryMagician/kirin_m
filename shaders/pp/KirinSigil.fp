// fade-in logo

void main()
{
	vec2 bresl = textureSize(InputTexture,0);
	vec2 lresl = textureSize(basetex,0);
	float ar = bresl.x/bresl.y;
	float sar = lresl.x/lresl.y;
	vec2 uv = TexCoord-vec2(.5);
	uv.x *= ar/sar;
	uv = clamp(-uv*.75+vec2(.5),0.,1.);
	vec3 col = texture(basetex,uv).rgb;
	float fade = clamp(2.*timer,0.,1.)-20.*pow(texture(fadetex,uv).x,.35)+2.*texture(glowtex,uv).x+timer;
	fade = clamp(fade,0.,1);
	fade *= .9+.2*texture(noisetex,vec2(timer*.1,.1)).x;
	vec3 res = col*fade;
	col = texture(bloomtex,uv).rgb;
	fade = clamp(timer-20.,0.,10.)*.05;
	fade *= .9+.2*texture(noisetex,vec2(timer*.1,.2)).x;
	res += col*fade*.5;
	FragColor = vec4(res,1.);
}
