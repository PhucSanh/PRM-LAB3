'use strict';
const {createHash} = require('node:crypto');
const {isDeepStrictEqual} = require('node:util');
const {FieldValue} = require('firebase-admin/firestore');
const validId = s => typeof s === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(s);
const eventKey = (kind, id) => `${kind}-${createHash('sha256').update(id).digest('hex').slice(0,40)}`;

function createNotificationEvents(db) {
  // Transactional create-once: retries must not replace readAt or re-trigger FCM.
  async function writeOnce(tx, uid, id, item) {
    const ref = db.doc(`users/${uid}/notifications/${id}`);
    const previous = await tx.get(ref);
    return () => { if (!previous.exists) tx.create(ref, {
      ...item, recipientUid: uid, receivedAt: FieldValue.serverTimestamp(),
    }); };
  }
  async function scheduleChanged({eventId, ownerUid, actorUid, taskId, before, after}) {
    if (![ownerUid, actorUid, taskId].every(validId) || actorUid === ownerUid || !eventId) return;
    const content = value => value && Object.fromEntries(Object.entries(value).filter(([key]) => key !== 'revision'));
    if (isDeepStrictEqual(content(before), content(after))) return;
    await db.runTransaction(async tx => {
      const grant = await tx.get(db.doc(`users/${ownerUid}/caregivers/${actorUid}`));
      if (!grant.exists) return;
      const write = await writeOnce(tx, ownerUid, eventKey('schedule', eventId), {
        kind: 'family', event: 'schedule_changed',
        title: after ? (before ? 'Lịch của Bác đã thay đổi' : 'Có việc mới trong lịch') : 'Một việc đã được gỡ khỏi lịch',
        body: 'Người thân đã cập nhật lịch. Mở Hôm nay để kiểm tra nhé.', route: '/today',
      });
      write();
    });
  }
  async function completed({ownerUid, completionId, before, after}) {
    if (!validId(ownerUid) || typeof completionId !== 'string' || completionId !== `${after?.taskId}_${after?.date}` || after?.status !== 'done' || before?.status === 'done' ||
        !validId(after.taskId) || !/^\d{4}-\d{2}-\d{2}$/.test(after.date || '')) return;
    await db.runTransaction(async tx => {
      // Route to the single caregiver that created the activity. Old activities
      // without creatorUid deliberately remain inbox-only/no-push recipients.
      const taskRef=db.doc(`users/${ownerUid}/tasks/${after.taskId}`);
      const [task, elder, completion] = await Promise.all([
        tx.get(taskRef), tx.get(db.doc(`users/${ownerUid}`)),
        tx.get(db.doc(`users/${ownerUid}/completions/${completionId}`)),
      ]);
      const creatorUid=task.data()?.creatorUid;
      if (!task.exists || !validId(creatorUid) || completion.data()?.status !== 'done') return;
      const [grant, caregiver] = await Promise.all([
        tx.get(db.doc(`users/${ownerUid}/caregivers/${creatorUid}`)),
        tx.get(db.doc(`users/${creatorUid}`)),
      ]);
      if (!grant.exists || caregiver.data()?.pairedMomUid !== ownerUid) return;
      const elderName=typeof elder.data()?.displayName==='string'&&elder.data().displayName.trim()?elder.data().displayName.trim():'Người lớn tuổi';
      const title=typeof task.data()?.title==='string'&&task.data().title.trim()?task.data().title.trim():'hoạt động';
      const when=after.date.split('-').reverse().join('/')+' '+new Date().toLocaleTimeString('vi-VN',{hour:'2-digit',minute:'2-digit',hour12:false});
      const write = await writeOnce(tx, creatorUid, eventKey('completed', `${ownerUid}/${completionId}`), {
        kind:'family', event:'task_completed', parentUid:ownerUid,
        title:`${elderName} đã hoàn thành: ${title}`,
        body:`Hoàn thành lúc ${when}.`,
        route:`/caregiver/task/${encodeURIComponent(after.taskId)}?date=${after.date}`,
      });
      write();
    });
  }
  async function pairingChanged({eventId, ownerUid, childUid, before, after}) {
    if (![ownerUid, childUid].every(validId) || !eventId || Boolean(before) === Boolean(after)) return;
    const linked = Boolean(after);
    await db.runTransaction(async tx => {
      const [parent, child] = await Promise.all([
        tx.get(db.doc(`users/${ownerUid}`)), tx.get(db.doc(`users/${childUid}`)),
      ]);
      const writes = [];
      for (const [uid, profile] of [[ownerUid, parent], [childUid, child]]) {
        if (!profile.exists) continue;
        writes.push(await writeOnce(tx, uid, eventKey('pairing', eventId), {
          kind: 'system', event: linked ? 'pairing_linked' : 'pairing_revoked',
          title: linked ? 'Đã kết nối với người thân' : 'Kết nối với người thân đã ngưng',
          body: linked ? 'Hai máy đã được ghép nối để cùng hỗ trợ lịch sinh hoạt.' : 'Quyền xem và lập lịch qua kết nối này đã kết thúc.',
          route: '/inbox',
        }));
      }
      writes.forEach(write => write());
    });
  }
  return {scheduleChanged, completed, pairingChanged};
}
module.exports = {createNotificationEvents, eventKey};
