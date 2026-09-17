// Pass this function to chrome-devtools-axi eval on the localhost validation
// export after pressing M twice. Then eval frontierSmoke.combat(), builder(),
// in order. After reloading, use frontierCommand({action: 'load'} as JSON)
// and compare frontier.state with JSON.parse(localStorage.frontierExpected).
async () => {
  const checks=[];
  const check=(ok,name)=>{if(!ok) throw Error(name); checks.push(name);};
  const wait=ms=>new Promise(r=>setTimeout(r,ms));
  const until=async predicate=>{for(let i=0;i<100;i++){if(predicate())return;await wait(200);}throw Error('simulation timeout');};
  const cmd=async(action,extra={})=>{
    window.frontierCommand(JSON.stringify({action,...extra}));
    await wait(650); return window.frontier;
  };
  window.frontierSmoke={
    combat: async()=>{
      await cmd('night'); await cmd('arena');
      let s=await cmd('hurt',{amount:45}); check(s.state.health===55,'damage');
      s=await cmd('eat'); check(s.state.health===95 && s.state.food===2,'snack heals');
      s=await cmd('fire'); check(s.state.loaded.revolver===5,'raycast gunfire');
      await cmd('reload'); await until(()=>frontier.reload===0);
      check(frontier.state.loaded.revolver===6,'reload');
      await cmd('fire'); await wait(2200); await cmd('fire'); await until(()=>frontier.mode==='dawn');
      s=frontier;
      check(s.state.day===2 && s.mode==='dawn' && s.state.structures[0].remaining===0 && s.allies===1,'victory wage and one-night post');
      await cmd('shop',{id:'General Store'});
      s=await cmd('buy',{id:'armor'}); check(s.state.armor===75,'armor purchase');
      return {checks,state:s.state};
    },
    builder: async()=>{
      for(let i=0;i<2;i++){await cmd('night');await cmd('clear');await wait(1000);}
      await cmd('site',{site:1});
      let s=await cmd('build',{id:'tower'}); check(s.state.structures[1].remaining===2,'tower begins');
      await cmd('site',{site:2}); const money=s.state.money;
      s=await cmd('build',{id:'guard_post'}); check(s.state.structures.length===2 && s.state.money===money,'combined limit');
      await cmd('night'); await cmd('bell_failure'); check(frontier.mode==='defeat','bell failure');
      s=await cmd('load'); check(s.state.structures[1].remaining===2 && s.phase==='day','retry preserves construction');
      await cmd('night');await cmd('clear');await wait(1000);
      check(frontier.state.structures[1].remaining===1,'tower halfway');
      await cmd('night');await cmd('clear');await wait(1000);
      check(frontier.state.structures[1].remaining===0 && frontier.allies===2,'two-night tower complete');
      await cmd('title');await wait(2500);
      localStorage.setItem('frontierExpected',JSON.stringify(frontier.state));
      return {checks,state:frontier.state};
    }
  };
  check(frontier.audio_unlocked && !frontier.muted && frontier.ambience,'gesture unlock and unmute');
  let s=await cmd('new');check(s.state.money===220 && s.mode==='playing','New Game');
  await cmd('shop',{id:'Saloon'});
  s=await cmd('buy',{id:'food'});check(s.state.food===3 && s.state.money===195,'food purchase');
  await cmd('shop',{id:'Gunsmith'});
  s=await cmd('buy',{id:'ammo'});check(s.state.money===160 && s.state.ammo.revolver===84,'ammo purchase');
  await cmd('site',{site:0});
  s=await cmd('build',{id:'guard_post'});check(s.state.money===10 && s.state.structures[0].remaining===1 && s.allies===0,'paid construction not instant');
  await cmd('shop',{id:'General Store'});
  s=await cmd('buy',{id:'armor'});check(s.state.money===10 && s.state.armor===0,'insufficient funds atomic');
  return {checks,state:s.state};
}
