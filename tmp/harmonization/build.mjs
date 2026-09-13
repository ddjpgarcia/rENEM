import fs from 'node:fs/promises';
import {Workbook,SpreadsheetFile} from '@oai/artifact-tool';
const scratch='C:/enemR-project/rENEM/tmp/harmonization';
const out='C:/enemR-project/rENEM/outputs/01a08271-1276-79c3-980d-1d55ded75b74';
const data=JSON.parse(await fs.readFile(scratch+'/workbook_data.json','utf8'));
const wb=Workbook.create();
function make(name,headers,rows,widths,height){
 const s=wb.worksheets.add(name);s.showGridLines=false;
 const n=rows.length+1,m=headers.length;
 s.getRangeByIndexes(0,0,n,m).values=[headers,...rows];
 s.getRangeByIndexes(0,0,n,m).format.font={name:'Arial',size:11,color:'#243247'};
 s.getRangeByIndexes(0,0,n,m).format.wrapText=true;
 s.getRangeByIndexes(0,0,n,m).format.verticalAlignment='top';
 s.getRangeByIndexes(1,0,n-1,m).format.rowHeight=height;
 if(['Resumen','Detalle','Preguntas','Notas'].includes(name)){
  rows.forEach((row,i)=>{
   const lines=Math.max(...row.map((v,j)=>Math.ceil(String(v??'').length/(widths[j]*0.95))));
   s.getRangeByIndexes(i+1,0,1,m).format.rowHeight=Math.max(40,Math.min(270,lines*14+12));
  });
 }
 widths.forEach((w,i)=>s.getRangeByIndexes(0,i,n,1).format.columnWidth=w);
 const t=s.tables.add(s.getRangeByIndexes(0,0,n,m),true,'ENEM'+name);t.style='TableStyleLight9';
 s.getRangeByIndexes(0,0,1,m).format={fill:'#273E56',font:{name:'Arial',size:11,bold:true,color:'#FFFFFF'},wrapText:true,rowHeight:44};
 s.freezePanes.freezeRows(1);
 return s;
}
const order={'Priorizar':0,'Con ajustes':1,'Revisar antes':2,'No unir directamente':3,'Conservar como auxiliar':4,'Solo subserie':5};
data.summary.sort((a,b)=>order[a[5]]-order[b[5]]||a[2].localeCompare(b[2])||a[1].localeCompare(b[1]));
const s=make('Resumen',['Concepto ID','Concepto','Tema','Olas con variable','Olas con datos provisionales','Decisión propuesta','Diferencias y limitaciones','Regla propuesta',...data.years.map(String)],data.summary,[22,39,19,16,21,25,65,61,...data.years.map(()=>19)],124);
s.getRange('D2:D52').formulas=data.summary.map((r,i)=>[`=10-COUNTIF(I${i+2}:R${i+2},"No localizado")`]);
s.getRange('D2:E52').setNumberFormat('0');
s.getRange('F2:F52').conditionalFormats.add('containsText',{text:'Priorizar',format:{fill:'#E1EFE2',font:{color:'#23502C',bold:true}}});
s.getRange('F2:F52').conditionalFormats.add('containsText',{text:'Revisar antes',format:{fill:'#FFF0CC',font:{color:'#765514'}}});
s.getRange('F2:F52').conditionalFormats.add('containsText',{text:'No unir directamente',format:{fill:'#FBE5E3',font:{color:'#8B302D'}}});

const detailRows=data.details.map(r=>[r[0],r[1],r[2],r[3],r[4],r[5],r[6],r[8],r[9],r[10],r[11],r[16],r[17]]);
const d=make('Detalle',['Concepto ID','Concepto','Año','Localización','Variable original/mapeada','Recodificada existente','Etiqueta Stata (puede estar truncada)','N de la base','Perdidos del sistema','N útil provisional','Fracción útil provisional','Notas','Fuente de datos'],detailRows,[22,35,9,19,24,26,68,14,18,18,19,72,33],125);
d.getRange(`C2:C${detailRows.length+1}`).setNumberFormat('0');
d.getRange(`H2:J${detailRows.length+1}`).setNumberFormat('#,##0');
d.getRange(`K2:K${detailRows.length+1}`).formulas=detailRows.map((r,i)=>[r[3]==='Localizado'?`=J${i+2}/H${i+2}`:'=""']);
d.getRange(`K2:K${detailRows.length+1}`).setNumberFormat('0.0%');

const questionRows=data.details.filter(r=>r[3]==='Localizado').map(r=>[r[0],r[1],r[2],r[4],r[6],r[15],r[13],r[14],r[12]]);
const q=make('Preguntas',['Concepto ID','Concepto','Año','Variable','Etiqueta Stata (puede estar truncada)','Fragmento literal del cuestionario (contexto; revisar subítem)','Cuestionario','Página PDF','Método de localización'],questionRows,[22,35,9,22,65,120,48,15,56],250);
q.getRange(`C2:C${questionRows.length+1}`).setNumberFormat('0');q.getRange(`H2:H${questionRows.length+1}`).setNumberFormat('0');
// Excerpts have at most 1,500 characters; 250 pt rows at this width keep them legible.

const c=make('Codigos',['Concepto ID','Concepto','Año','Variable','Tipo de variable','Código almacenado','Etiqueta de valor','Casos sin ponderar','Tipo de código','Fuente'],data.codes,[22,35,9,25,26,21,85,19,34,33],48);
c.getRange(`C2:C${data.codes.length+1}`).setNumberFormat('0');c.getRange(`H2:H${data.codes.length+1}`).setNumberFormat('#,##0');
const inv=make('Inventario',['Año','Variable','Etiqueta legible (puede estar truncada)','Etiqueta Stata sin normalizar','N de la base','Perdidos del sistema','Fracción perdida del sistema','Valores únicos sin NA','Tipo de dato','Códigos etiquetados','Conceptos evaluados','Fuente'],data.inventory,[9,28,73,73,15,19,22,21,17,20,58,33],44);
inv.getRange(`E2:F${data.inventory.length+1}`).setNumberFormat('#,##0');
inv.getRange(`G2:G${data.inventory.length+1}`).formulas=data.inventory.map((r,i)=>[`=F${i+2}/E${i+2}`]);
inv.getRange(`G2:G${data.inventory.length+1}`).setNumberFormat('0.0%');
data.notes.splice(3,0,['Resultado','Se localizaron campos para 39 de los 51 conceptos en las diez olas. 29 conceptos se proponen para priorizar o armonizar con ajustes. Esto no significa que estén armonizados ni validados para cualquier análisis.']);
data.notes[4][1]='Empezar por Resumen; filtrar olas con variable = 10 y revisar decisión/advertencias. Detalle contiene variables y disponibilidad por año; Preguntas guarda fragmentos y fuentes. Codigos desglosa originales/recodificadas. Inventario incluye todas las columnas.';
make('Notas',['Tema','Detalle'],data.notes,[33,125],100);

for(const row of data.summary){if(row.length!==18)throw Error('Summary shape');}
const totals=new Map();for(const r of data.inventory){if(totals.has(r[0])&&totals.get(r[0])!==r[4])throw Error('N inconsistent');totals.set(r[0],r[4]);}
if([...totals.values()].reduce((a,b)=>a+b,0)!==20317||data.inventory.length!==3305)throw Error('Source totals');
if(data.details.find(r=>r[0]==='isco'&&r[2]===2021)[10]!==0)throw Error('ISCO invalid');
const summaryCheck=await wb.inspect({kind:'table',range:'Resumen!A1:F7',tableMaxRows:7,tableMaxCols:6,maxChars:2500});console.log(summaryCheck.ndjson);
console.log((await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#NUM!|#SPILL!',options:{useRegex:true,maxResults:25},maxChars:1500})).ndjson);
await fs.mkdir(out,{recursive:true});
for(const [name,range] of [['Resumen','A1:H5'],['Detalle','A1:G4'],['Preguntas','D1:I3'],['Codigos','A1:J7'],['Inventario','A1:F6'],['Notas','A1:B6']]){
 console.log('Rendering '+name);
 const img=await wb.render({sheetName:name,range,scale:1,format:'png'});
 await fs.writeFile(scratch+'/'+name+'.png',new Uint8Array(await img.arrayBuffer()));
}
console.log('Exporting workbook');
const xlsx=await SpreadsheetFile.exportXlsx(wb);
await xlsx.save(out+'/ENEM_candidatos_armonizacion_1997_2024.xlsx');
console.log('Saved workbook');
