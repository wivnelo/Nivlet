#include "../Native/keep_awake.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
static unsigned nextID, calls, creates, releases, failBits;
static bool live[1000];
static int create(bool display, uint32_t *identifier) {
    (void)display;
    unsigned call = calls++;
    if (call < 32 && (failBits & (1u << call))) return -1;
    *identifier = ++nextID;live[*identifier] = true;creates++;return 0;
}
static int release(uint32_t identifier) {
    assert(identifier && identifier <= nextID && live[identifier]);
    unsigned call = calls++;
    if (call < 32 && (failBits & (1u << call))) return -1;
    assert(identifier != 1); /* An assertion owned by another subsystem. */
    live[identifier] = false;releases++;return 0;
}
static void reset(void) {
    memset(live,0,sizeof(live));nextID=1;live[1]=true;calls=creates=releases=failBits=0;
}
static void checkOwnership(NivletKeepAwake state) {
    for (unsigned id=2;id<=nextID;id++) assert(live[id] == (id==state.system || id==state.display));
    assert(live[1]);
}
int main(void) {
    unsigned scenarios=0;
    for(unsigned before=0;before<3;before++) for(unsigned after=0;after<4;after++) {
        for(unsigned failures=0;failures<256;failures++) {
            reset();NivletKeepAwake state={0};bool restored=false;
            assert(nivletSetKeepAwake(&state,before>0,before==2,create,release,&restored));
            calls=0;failBits=failures;
            bool awake=(after & 1)!=0, display=awake && (after & 2)!=0;
            bool ok=nivletSetKeepAwake(&state,awake,display,create,release,&restored);
            checkOwnership(state);
            if(ok){assert((state.system!=0)==awake);assert((state.display!=0)==display);}
            else if(restored){assert((state.system!=0)==(before>0));assert((state.display!=0)==(before==2));}
            calls=0;failBits=0;
            assert(nivletStopKeepAwake(&state,release));checkOwnership(state);
            unsigned total=calls;assert(nivletStopKeepAwake(&state,release));assert(calls==total);
            assert(creates==releases);scenarios++;
        }
    }
    reset();NivletKeepAwake state={0};bool restored;
    assert(nivletSetKeepAwake(&state,true,true,create,release,&restored));
    unsigned total=calls;
    for(int i=0;i<100000;i++) assert(nivletSetKeepAwake(&state,true,true,create,release,&restored));
    assert(calls==total && creates==2);
    calls=0;failBits=1;assert(!nivletStopKeepAwake(&state,release));
    assert(!state.system && state.display);checkOwnership(state);
    failBits=0;assert(nivletStopKeepAwake(&state,release));checkOwnership(state);
    printf("%u transition/failure scenarios; 100000 idempotent saves; shutdown retries and foreign assertion preserved\n",scenarios);
}
