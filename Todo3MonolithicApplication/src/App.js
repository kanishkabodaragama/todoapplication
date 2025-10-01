import React from 'react';
export default function App(){
  const [todos, setTodos] = React.useState([]);
  React.useEffect(()=>{
    try { const v = JSON.parse(localStorage.getItem('todos')||'[]'); setTodos(Array.isArray(v)?v:[]); } catch { }
  },[]);
  React.useEffect(()=>{ try { localStorage.setItem('todos', JSON.stringify(todos)) } catch { } },[todos]);
  return React.createElement('div',{style:{fontFamily:'Arial',padding:20}},React.createElement('h1',null,'Todo3 Monolithic (Dev)'),React.createElement('pre',null,JSON.stringify(todos)));
}
