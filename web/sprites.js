/* Original sprites drawn by hand as indexed pixel rows. No image files or generated art. */
'use strict';
const Pixel = (() => {
const heroes = [
[
'......oooo......','.....oggggo.....','.....oghhgo.....','....oggggggo....',
'....okkkkbbo....','....okekebbo....','.....osssbo.....','......ossso.....',
'...ooobbbbooo...','..obbbhbbhbbbo..','..obbhhbbhhbbo..','.ogobbbbbbbobbo.',
'.oggobhhhhboabbo','.oggoobbbboabbo.','.oggoohhhhoabbo.','.oggoobbbboabbo.',
'..oo.ohhhho.oo..','.....obbbbo.....','.....obbobo.....','....obbboobbo...',
'....obbboobbo...','....okko.okko...','...okkkookkkko..','...oooo..oooo...'],
[
'.......oo.......','......oppo......','.....oppppo.....','....opplpppo....',
'...opplllpppo...','..oppppppppppo..','....oksskko.....','....oseesko.....',
'.....osssko.....','......ossko.....','....ooppppoo....','...opplppplpo...',
'...opplppplpo.o.','...oplppppploao.','..opplppppplobo.','..opplpllpplobo.',
'..opplpllpplobo.','..opplppppplobo.','.opplpppppplobo.','.opplplllpplobo.',
'.oppppppppppobo.','..ooooooooooobo.','....okko.okko...','...okkkookkkko..'],
[
'......oooo......','.....occcco.....','....occhhcco....','...occhhhhcco...',
'...occkkkkcco...','...ocsekescco...','....osssssco....','.....osssoo.....',
'....ooccccoo....','...occlcclcco...','...occlcclcco...','..ococlccococo..',
'..oaooccco.oao..','..oaaoooao.oao..','...oaocccoaoo...','....oocccco.....',
'....occllco.....','....occccclo....','....ockkkco.....','....ockokco.....',
'....ock.okco....','....okk.okko....','...okkko.kkko...','...oooo..oooo...']];
const bossRows=[
'.......oo......oo.......','......oggo....oggo......','.....oggggo..oggggo.....','.....ogghggooghgggo.....',
'......oghggggghgo.......','......ogggggggggo.......','.....ogkkkkkkkgggo......','.....okkrkkkrkkkko......',
'.....okkrkkkrkkkko......','.....okkkkkkkkkkko......','......okhhhhhhkko.......','......okhkhhkhkko.......',
'....ooobbbbbbbbooo......','...obbbbbhbhbbbbbbbo....','..obbbbbhhbhhbbbbbbbo...','.obbbbohhhhhhhobbbbbo...',
'.obbbbohhhhhhhoobbbbo...','obbbb.obbhhhbbo.obbbbo..','obbbb.obbbbbbbbo.obbbbo.','okkkkoobbhhhbbbo.okkkko.',
'okkkkoobbbbbbbbo.okkkko.','.oooolobbbbbbbboloooo...','....olobbbhbbbbolo......','....olobbbhbbbbolo......',
'....olobbbbbbbbolo......','....olobbbobbbbolo......','....olobbb.obbblo.......','.....oobbb.obbbbo.......',
'.....obbbb.obbbbbo......','....obbbbb.obbbbbbo.....','....oooooo.ooooooo......'];
const bellRows=[
'.........oooo...........','........ohhhho..........','.......ohhhhho..........','......ohhhhhho..........',
'.....ohhhhhhhho.........','.....ohkkkkkkho.........','.....ohkrrrrkho.........','.....ohkkkkkkho.........',
'.....ohkkkkkkho.........','....ohhkkkkkkhho........','...ohhhhkkkhhhhho.......','..ohhhhhhhhhhhhhho......',
'..oooooooooooooooo......','.......obbbbo...........','......obbhhbbo..........','.....obbhhhhbbo.........',
'....obbhohhobhbo........','...obbhhoooohhbbo.......','..obbhohhhhhhobhbo......','..obbhohhhhhhobhbo......',
'...obbohhhhhhobbo.......','....obohhhhhhobo........','...obbohhhhhhobbo.......','..obbbohhhhhhobbbo......',
'..obbbobbbbbbobbbo......','.obbbbohhhhhhobbbbo.....','.obbbbobbbbbbobbbbo.....','..obbbbohhhhobbbbo......',
'...obbbboooobbbbo.......','....obbo....obbo........','.....oo......oo.........'];
const crownRows=[
'......go......og........','.....ogggo..ogggo.......','.....oghggooghhgo.......','......oggggggggo........',
'......oghhhhhgo.........','......okkkkkkko.........','......okrrrrkko.........','......okhhhhkko.........',
'.......okhhkko..........','.....ooobbbbooo.........','....ogggbhhbggggo.......','...oghhgbhhbghhggo......',
'...oghbgbhhbgbhggo......','..oghbbgbhhbgbbhggo.....','..oghbbgbbbbg bbhggo....','..okkbbohhhoobbkko......',
'..okkbohhhhhhobkko......','...ooobhhhhhhbooo.......','.....obbbhbbbbo.........','.....obbbhbbbbo.........',
'....obbbbhbbbbbo........','....obbbbhbbbbbo........','...obbbbbhbbbbbbo.......','...obbbbbhbbbbbbo.......',
'...obbbbbhbbbbbbo.......','....obbbbhbbbbo.........','.....obbbobbbo..........','.....ohho.ohho..........',
'.....ohho.ohho..........','....ohhho.ohhho.........','....ooooo.ooooo.........'];
const npcRows=[
'......oooo......','.....occcco.....','....occllcco....','...occllllcco...',
'...occkkkkcco...','...ockseeskco...','....okssssko....','.....osssso.....',
'....ooccccoo....','...occcllccco...','..occclllclcco..','..occlcllclcco..',
'.occclcllclccco.','.occllcllcllcco.','.occcclllclccco.','.occcclllclccco.',
'.occllcllcllcco.','.occllcllcllcco.','occllclllclllcco','occcccccccccccco',
'.oooooooooooooo.','....okk..kko....','...okkkookkko...','...oooo..oooo...'];
const pals=[{o:'#172233',g:'#d8b66d',h:'#e9f0d8',b:'#6c91b0',k:'#334157',s:'#e7b791',e:'#172233',a:'#b77d56'},
{o:'#172233',p:'#9377b5',l:'#c6a0d1',k:'#3b3957',s:'#edbf9c',e:'#172233',a:'#f9d46f',b:'#a5724b'},
{o:'#172233',c:'#5d9d8b',h:'#a4cf9d',l:'#8bbf98',k:'#33444e',s:'#e4b58c',e:'#172233',a:'#e0e6d5'}];
function matrix(ctx, rows, pal, x,y,s=1,flip=false){ctx.save();if(flip){ctx.translate(x+rows[0].length*s,y);ctx.scale(-1,1);x=0;y=0;}for(let j=0;j<rows.length;j++)for(let i=0;i<rows[j].length;i++){const c=pal[rows[j][i]];if(c){ctx.fillStyle=c;ctx.fillRect(Math.round(x+i*s),Math.round(y+j*s),s,s);}}ctx.restore();}
function hero(ctx,id,x,y,s=1,t=0,down=false){if(down){ctx.save();ctx.globalAlpha=.5;ctx.translate(x,y+24*s);ctx.rotate(-Math.PI/2);matrix(ctx,heroes[id],pals[id],0,0,s);ctx.restore();return;}matrix(ctx,heroes[id],pals[id],x,y-Math.floor(Math.sin(t*2+id)*.7)*s,s);}
function boss(ctx,id,x,y,s=1,t=0,enraged=false){const sets=[{g:'#8ca07a',h:'#d7c892',b:'#587b72',k:'#29374b',r:'#ffb965',l:'#476355'}, {g:'#8b82bb',h:'#d6c7df',b:'#645789',k:'#292c4e',r:'#a9edee',l:'#463a68'}, {g:'#ce9856',h:'#ffe3a5',b:'#985955',k:'#3a2f44',r:'#aaf5cb',l:'#633b45'}];const p={...sets[id],o:'#182236'};if(enraged){p.r='#ff5d69';p.b=id===2?'#b54e54':'#96615f';}matrix(ctx,[bossRows,bellRows,crownRows][id],p,x,y-Math.floor(Math.sin(t*2)*.6)*s,s);if(id===1){ctx.fillStyle='#b9e3e8';for(let i=0;i<3;i++)ctx.fillRect(x+(i*8+3)*s,y+(34+Math.sin(t*2+i)*2)*s,3*s,s);}if(id===2){ctx.fillStyle='#f9cb6b';for(let i=0;i<3;i++){ctx.fillRect(x+(8+i*3)*s,y-3*s,s,3*s);ctx.fillRect(x+(8+i*3)*s,y-4*s,s,s);}}}
function rect(ctx,x,y,w,h,c){ctx.fillStyle=c;ctx.fillRect(Math.round(x),Math.round(y),w,h);}
function tree(ctx,x,y,s=1){rect(ctx,x+7*s,y+15*s,3*s,15*s,'#3e4b49');for(let i=0;i<4;i++){const w=(7+i*5)*s;rect(ctx,x+8*s-w/2,y+i*5*s,w,7*s,i%2?'#355b52':'#487865');rect(ctx,x+7*s-w/2,y+i*5*s,w/2,2*s,'#658e70');}}
function scene(ctx,id=0,t=0,party=true){const w=320,h=200;ctx.clearRect(0,0,w,h);rect(ctx,0,0,w,h,'#18273d');for(let i=0;i<38;i++){rect(ctx,(i*79+21)%320,(i*i*13+9)%100,1,1,i%3?'#879eac':'#f0dba6');}rect(ctx,232,19,23,23,'#e5d9b0');rect(ctx,228,23,31,15,'#e5d9b0');rect(ctx,229,19,14,19,'#18273d');for(let i=0;i<9;i++){rect(ctx,i*41-14,80-(i%3)*12,56,65,'#263c4a');rect(ctx,i*41-11,76-(i%3)*12,44,8,'#263c4a');}rect(ctx,0,126,320,74,'#304e48');rect(ctx,0,128,320,3,'#60856a');for(let y=141;y<200;y+=12){const wid=(y-123)*2.7;rect(ctx,160-wid/2,y,wid,12,'#8c8b68');rect(ctx,160-wid/2,y,wid,2,'#aaa079');for(let x=0;x<320;x+=31)if(x>160-wid/2&&x<160+wid/2)rect(ctx,x,y,1,10,'#797e5f');}for(let i=0;i<20;i++){let x=(i*71+7)%320,y=140+(i*23)%57;if(Math.abs(x-160)>(y-123)*1.4){rect(ctx,x,y,3,1,'#7b9c6c');rect(ctx,x+1,y-2,1,3,'#7b9c6c');}}
 tree(ctx,20,92,2);tree(ctx,278,100,2);tree(ctx,53,93,1);tree(ctx,256,92,1);
 if(id===0||id===4){rect(ctx,112,77,9,61,'#526477');rect(ctx,114,78,3,60,'#80949a');rect(ctx,104,73,25,7,'#9aaba9');rect(ctx,104,69,25,4,'#526477');rect(ctx,117,56,2,15,'#9aaba9');rect(ctx,111,60,13,2,'#9aaba9');}
 if(id===1){rect(ctx,123,117,57,22,'#745444');rect(ctx,120,111,63,7,'#b08254');for(let i=0;i<5;i++){rect(ctx,120+i*13,90,13,22,i%2?'#b27673':'#ead3a0');}rect(ctx,119,90,2,50,'#b6a37b');rect(ctx,182,90,2,50,'#b6a37b');rect(ctx,144,120,10,7,'#edc772');}
 if(id===2){rect(ctx,128,119,52,22,'#3d5a61');rect(ctx,124,115,60,6,'#a2b3a2');rect(ctx,134,119,40,8,'#6fa5ac');for(let i=0;i<4;i++)rect(ctx,139+i*8,120,4,1,'#b3e0ca');}
 if(id===3){for(let i=0;i<3;i++){rect(ctx,130+i*20,115,10,25,'#69818a');rect(ctx,128+i*20,110,14,8,'#91a29f');rect(ctx,134+i*20,118,2,13,'#374957');}}
 if(id===5){rect(ctx,116,94,54,43,'#465a67');rect(ctx,112,89,62,7,'#7f9290');rect(ctx,125,105,10,32,'#243c49');rect(ctx,150,105,10,32,'#243c49');rect(ctx,118,80,6,12,'#7f9290');rect(ctx,161,80,6,12,'#7f9290');}
 const npcPal={o:'#192536',c:['#827392','#b17d55','#6a9a91','#737e9e','#a48469','#6e839e'][id],l:'#c1b5a1',k:'#28364a',s:'#d6b594',e:'#182435'};matrix(ctx,npcRows,npcPal,192,100,2);rect(ctx,220,123,3,23,'#96754e');rect(ctx,218,117,7,8,'#f3cc77');rect(ctx,220,119,3,4,'#fff0ab');
 if(party){hero(ctx,0,98,144,2,t);hero(ctx,1,140,150,2,t);hero(ctx,2,182,144,2,t);}for(let i=0;i<9;i++){let x=(i*53+t*7)%320,y=127+Math.sin(t+i*7)*10;rect(ctx,x,y,1,1,'#e8c879');}}
function portrait(canvas,id){canvas.width=24;canvas.height=32;const ctx=canvas.getContext('2d');ctx.imageSmoothingEnabled=false;hero(ctx,id,4,4,1,0);}
function icon(canvas,face){const c=canvas.getContext('2d');c.clearRect(0,0,16,16);const r=(x,y,w,h,col)=>rect(c,x,y,w,h,col);if(['strike','cleave','stab'].includes(face)){r(3,1,4,10,'#1a2535');r(4,1,2,9,'#e7e7c7');r(5,2,2,7,'#92b3bc');r(1,10,9,2,'#d6ad66');r(4,12,3,3,'#9f7350');}else if(['bolt','nova'].includes(face)){r(6,1,4,3,'#f9da8c');r(4,4,8,6,'#e59b77');r(6,3,4,9,'#fff0b5');r(1,6,3,2,'#d9acd9');r(12,7,3,2,'#d9acd9');r(7,12,2,3,'#cf8272');}else if(['heal','bloom'].includes(face)){r(5,1,6,14,'#285b51');r(1,5,14,6,'#285b51');r(6,2,4,12,'#a5e2aa');r(2,6,12,4,'#a5e2aa');r(7,3,2,10,'#daf1bb');}else if(['guard','ward'].includes(face)){r(2,2,12,8,'#bcdad7');r(3,10,10,2,'#bcdad7');r(5,12,6,2,'#bcdad7');r(7,14,2,1,'#bcdad7');r(4,4,8,5,'#6e9daf');r(6,9,4,3,'#6e9daf');r(7,4,2,7,'#e9d398');}else if(['shot','venom'].includes(face)){for(let i=0;i<9;i++){r(3+Math.floor(Math.sin(i/8*Math.PI)*6),i+3,2,2,'#d5ae70');}r(3,3,1,10,'#d5e3cb');r(2,7,12,1,'#b8d7ad');r(12,6,3,3,'#d5e3cb');}else if(face==='dash'){r(3,2,5,9,'#89baa4');r(6,8,5,5,'#a4dbb3');r(2,12,11,2,'#dae7c1');r(1,4,2,1,'#d6e5b5');r(0,7,2,1,'#d6e5b5');}else{r(5,5,7,6,'#b9bea1');r(7,4,3,1,'#e1e2b8');r(4,7,1,3,'#7c8f82');r(6,11,5,1,'#7c8f82');}}
return {hero,boss,scene,portrait,rect,icon};
})();
