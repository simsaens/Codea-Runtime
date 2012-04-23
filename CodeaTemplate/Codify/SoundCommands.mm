//
//  SoundCommands.c
//  Codea
//
//  Created by Dylan Sale on 29/09/11.
//  
//  Copyright 2012 Two Lives Left Pty. Ltd.
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  

#import "SoundCommands.h"
#import "sfxr.h"
#import "ObjectAL.h"

#import "decode.h"
#import "encode.h"


#import <iostream>
#import <sstream>

#ifdef __cplusplus
extern "C" {
#endif    
    #import "LuaState.h"    
    #import "lua.h"
    #import "lauxlib.h"
    #import "soundbuffer.h"
#ifdef __cplusplus
}
#endif  


sfxr sfxrInstance;

#define BYTES_IN_MEGABYTE (1024*1024)

//Store the buffers used in a LRU ordering, when the number of buffers is too large drop the oldest buffer
#include <list>
#include <map>
#include <locale>

typedef unsigned long HashType;

struct ALBufferWrapper
{
    ALBuffer* buffer;
    HashType hash;
    
    ALBufferWrapper(ALBuffer* b, HashType h) : buffer(b), hash(h)
    {
        [buffer retain];
    }
    
    ALBufferWrapper(const ALBufferWrapper& other)
    {
        buffer = other.buffer;
        hash = other.hash;
        [buffer retain];
    }
    
    ~ALBufferWrapper()
    {
        [buffer release];
    }
};

static HashType calculateHash(const char* str, size_t len)
{
    static std::locale loc;
    static const std::collate<char>& collate = std::use_facet< std::collate<char> >(loc);
    
    return collate.hash(str, str+len);
}

static bool calculateHashForSoundTypeAndSeed(const char* type, size_t len, lua_Integer seed, HashType* out_Hash)
{
    static const size_t bufferSize = 512;
    char buffer[bufferSize];
    size_t size =  snprintf(buffer, bufferSize, "%s%d", type, seed);
    if (size > bufferSize)
    {
        return false;
    }
    *out_Hash = calculateHash(buffer, size);
    return true;
}

class BufferCache
{
private:
    static const size_t kDefaultMaxBufferCacheSize = 2*BYTES_IN_MEGABYTE; //Set aside a few meg for the cache
    typedef std::list<ALBufferWrapper> BufferList;
    BufferList pool;
    
    typedef std::map<HashType, BufferList::iterator> HashDict;
    HashDict hashDict;
    
    size_t sizeBytes;

    size_t maxSizeBytes;

public:
    BufferCache() { reset(); }
    
    size_t getMaxSizeBytes() { return maxSizeBytes; }
    void setMaxSizeBytes(size_t size) { maxSizeBytes = size; }
    size_t getSizeBytes() { return sizeBytes; }
    
    void add(ALBuffer* buffer, HashType hash)
    {
        BufferList::iterator iter = pool.insert(pool.begin(), ALBufferWrapper(buffer, hash));
        hashDict[hash] = iter;
        sizeBytes += buffer.size;
        //NSLog(@"adding buffer of size %d",buffer.size);
        if (maxSizeBytes > 0 && sizeBytes > maxSizeBytes) 
        {
            NSLog(@"%d is too large, removing last used sound from cache", (int)sizeBytes);
            BufferList::iterator oldest = (--pool.end());
            sizeBytes -= oldest->buffer.size;
            NSLog(@"%d is the new size", (int)sizeBytes);
            hashDict.erase(oldest->hash);
            pool.pop_back();
        }
    }
    
    ALBuffer* find(HashType hash)
    {
        HashDict::iterator iter =  hashDict.find(hash);
        if (iter == hashDict.end()) 
        {
            return nil;
        }
        pool.splice(pool.begin(), pool, iter->second); //Move it to the start of the pool
        return iter->second->buffer;
    }
    
    void reset()
    {
        pool.clear();
        hashDict.clear();
        sizeBytes = 0;
        maxSizeBytes = kDefaultMaxBufferCacheSize;
    }
    
};

BufferCache bufferCache;

/////////////

static NSString* base64EncodeStream(std::istream& stream)
{
    base64::encoder encoder;
    std::stringstream encodedStream;
    encoder.encode(stream, encodedStream);
    
    return [NSString stringWithCString:encodedStream.str().c_str() encoding:NSUTF8StringEncoding];
}

NSString* encodeParametersShort(sfxr* instance)
{
    std::stringstream stream;
    instance->SaveSettingsShort(stream);
    return base64EncodeStream(stream);
}

NSString* encodeParametersFull(sfxr* instance)
{
    std::stringstream stream;
    instance->SaveSettings(stream);    
    return base64EncodeStream(stream);
}


static inline void playBuffer(OALSimpleAudio* audio, ALBuffer* soundbuffer, float volume = 1.0)
{
    [audio playBuffer:soundbuffer volume:volume pitch:1.0 pan:0.0 loop:NO];
}

ALBuffer* playSfxr(sfxr* instance, float volume = 1.0f)
{
    const size_t bufferIncrement = 20000; //took the length of random sounds and this was about average.
    unsigned char* buffer = 0; 
    size_t bufferLength = 0;
    int bytesWrittenToBuffer = 0;
    unsigned char* bufferWriteStart = buffer;
    
    while (instance->IsPlaying())
    {
        size_t bytesLeftInBuffer = bufferLength-bytesWrittenToBuffer;
        size_t numBytesToWrite = bufferIncrement;
        if(bytesLeftInBuffer == 0)
        {
            bufferLength += bufferIncrement;
            buffer = (unsigned char*)realloc(buffer, bufferLength);
        }
        else
        {
            numBytesToWrite = bytesLeftInBuffer;
        }
        
        bufferWriteStart = buffer+bytesWrittenToBuffer;
        int bytesWritten = (*instance)(bufferWriteStart,numBytesToWrite);
        bytesWrittenToBuffer += bytesWritten;
    }
    //buffer = (unsigned char*)realloc(buffer, bytesWrittenToBuffer);
    //NSLog(@"created sound buffer of size %d",bytesWrittenToBuffer);
    
    OALSimpleAudio* audio = [OALSimpleAudio sharedInstance]; //need to do this to make sure we have an audio context at this point.
    ALBuffer* soundbuffer = [ALBuffer bufferWithName:nil data:buffer size:bytesWrittenToBuffer format:AL_FORMAT_MONO16 frequency:44100];
    playBuffer(audio, soundbuffer, volume);
    return soundbuffer;
}

bool decodeParameters(const char* base64Encoding, sfxr *instance)
{
    std::stringstream stream((std::string(base64Encoding))); //extra parentheses are to disambiguate it from a function definition
    base64::decoder decoder;
    std::stringstream decodedStream;
    decoder.decode(stream,decodedStream);
    if (decodedStream.good()) 
    {
        instance->LoadSettings(decodedStream);
    }
    else
    {
        return false;
    }
    
    return true;
}
        
/*
static float getFloatFromParams_num(struct lua_State* L, const char* paramName, size_t paramNameLen)
{
    lua_pushlstring(L, paramName, paramNameLen);
    lua_gettable(L, 1);
    lua_Number num = luaL_checknumber(L, -1);
    lua_pop(L, 1);
    return num;
}

#define getFloatFromParamsLiteral(n)\
    getFloatFromParams_num(L,(n),(sizeof(n)/sizeof(char))-1)
*/
void setupSoundGlobals(LuaState *state)
{
    [state setGlobalString:@"blit" withName:@"SOUND_BLIT"];
    [state setGlobalString:@"explode" withName:@"SOUND_EXPLODE"];
    [state setGlobalString:@"hit" withName:@"SOUND_HIT"];
    [state setGlobalString:@"jump" withName:@"SOUND_JUMP"];
    [state setGlobalString:@"pickup" withName:@"SOUND_PICKUP"];
    [state setGlobalString:@"powerup" withName:@"SOUND_POWERUP"];
    [state setGlobalString:@"random" withName:@"SOUND_RANDOM"];
    [state setGlobalString:@"shoot" withName:@"SOUND_SHOOT"];
    [state setGlobalString:@"data" withName:@"DATA"];
    [state setGlobalString:@"encode" withName:@"ENCODE"];
    [state setGlobalString:@"decode" withName:@"DECODE"];    
    
    [state setGlobalInteger:(int)Noise withName:@"SOUND_NOISE"];
    [state setGlobalInteger:(int)SquareWave withName:@"SOUND_SQUAREWAVE"];
    [state setGlobalInteger:(int)Sawtooth withName:@"SOUND_SAWTOOTH"];
    [state setGlobalInteger:(int)SineWave withName:@"SOUND_SINEWAVE"];
    
    [state setGlobalInteger:(int)AL_FORMAT_MONO8 withName:@"FORMAT_MONO8"];
    [state setGlobalInteger:(int)AL_FORMAT_MONO16 withName:@"FORMAT_MONO16"];
    [state setGlobalInteger:(int)AL_FORMAT_STEREO8 withName:@"FORMAT_STEREO8"];
    [state setGlobalInteger:(int)AL_FORMAT_STEREO16 withName:@"FORMAT_STEREO16"];
    
    bufferCache.reset();
    
}

int soundBufferSize(struct lua_State* L)
{
    int n = lua_gettop(L);
    if (n >= 1) 
    {
        lua_Number sizeMB = luaL_checknumber(L, 1);
        size_t sizeBytes = (size_t)(sizeMB*BYTES_IN_MEGABYTE);
        bufferCache.setMaxSizeBytes(sizeBytes);
        
        return 0;
    }
    
    lua_pushnumber(L, bufferCache.getMaxSizeBytes()/((float)BYTES_IN_MEGABYTE));    
    lua_pushnumber(L, bufferCache.getSizeBytes()/((float)BYTES_IN_MEGABYTE));
    return 2;    
}

void readTableIntoSFXRInstance(struct lua_State *L, int index)
{
#define SETUP_VALUE_NAMED(_n, _f, _min, _max)\
{\
lua_pushliteral(L, #_n);\
lua_gettable(L, index);\
if(lua_isnumber(L,-1))\
{\
lua_Number num = lua_tonumber(L, -1);\
num = MAX((_min),MIN((_max),num));\
sfxrInstance.Set##_f(num);\
}\
lua_pop(L, 1);\
}        
    
#define SETUP_VALUE(_f) SETUP_VALUE_NAMED(_f,_f, -1, 1)
    
    {
        lua_pushliteral(L, "Waveform");
        lua_gettable(L, index);
        if (lua_isnumber(L, -1)) 
        {
            lua_Integer waveform = lua_tointeger(L, -1);
            sfxrInstance.SetWaveform((WaveformGenerator)waveform);
        }
        lua_pop(L, 1);
    }        
    
    SETUP_VALUE_NAMED(AttackTime, AttackTime, 0, 10)
    SETUP_VALUE_NAMED(SustainTime, SustainTime, 0, 10)
    SETUP_VALUE(SustainPunch)
    SETUP_VALUE_NAMED(DecayTime, DecayTime, 0, 10)
    
    SETUP_VALUE(StartFrequency)
    SETUP_VALUE(MinimumFrequency)
    SETUP_VALUE(Slide)
    SETUP_VALUE(DeltaSlide)
    SETUP_VALUE(VibratoDepth)
    SETUP_VALUE(VibratoSpeed)
    
    SETUP_VALUE(ChangeAmount)
    SETUP_VALUE(ChangeSpeed)
    
    SETUP_VALUE(SquareDuty)
    SETUP_VALUE(DutySweep)
    
    SETUP_VALUE(RepeatSpeed)
    SETUP_VALUE(PhaserSweep)
    
    SETUP_VALUE(LowPassFilterCutoff)
    SETUP_VALUE(LowPassFilterCutoffSweep)
    SETUP_VALUE(LowPassFilterResonance)
    SETUP_VALUE(HighPassFilterCutoff)
    SETUP_VALUE(HighPassFilterCutoffSweep)
    
    SETUP_VALUE_NAMED(Volume,SoundVolume,0,1)
    
#undef SETUP_VALUE        
#undef SETUP_VALUE_NAMED
}

int sound(struct lua_State* L)
{
    //sfxrInstance.SetSeed(time(NULL)); //This is to make sure if they didnt get a seed, something different keeps playing in case a seed was set recently.
    
    int randSeed = rand(); //save the current random number so we can reset the seed at the end
                           //SetSeed below will overwite the global seed, thus making future calls to rand
                           //deterministic if we don't do this.
    
    const char* sound_type = "random";
    size_t sound_type_len = 6;
    int n = lua_gettop(L);
    BOOL tableParams = NO;
    ALBuffer* cachedBuffer = nil;
    HashType hash;
    BOOL hasHash = NO;
    
    float volume = 1.0f;
    
    if( n >= 1) //first is the sound type, or a table with parameters
    {
        size_t len;
        const char* string = lua_tolstring(L, 1, &len);
        
        soundbuffer_type* soundbuffer = NULL;
        
        if(string)
        {
            sound_type = string;
            sound_type_len = len;
        }
        else if(lua_istable(L, 1))
        {
            if( n >= 2 )
            {
                volume = lua_tonumber(L, 2);
            }            
            
            tableParams = YES;
        }
        else if((soundbuffer = tosoundbuffer(L, 1)) != NULL)
        {
            if( n >= 2 )
            {
                volume = lua_tonumber(L, 2);
            }
            
            cachedBuffer = soundbuffer->buffer;
        }
    }
    
    if (tableParams) 
    {
        sfxrInstance.ResetParams();

        readTableIntoSFXRInstance(L, 1);
        
        sfxrInstance.PlaySample();
    }
    else if(cachedBuffer == NULL) //don't try to interpret sound_type if we already have a buffer to play
    {
        if (strcmp(sound_type, "data") == 0) 
        {
            if (n < 2) 
            {
                luaL_error(L, "data sound type requires data parameter");
                return 0;
            }
           
            size_t base64StringLen;
            const char* base64String = lua_tolstring(L, 2, &base64StringLen);
            
            if(!base64String)
            {
                luaL_error(L, "invalid data string given to sound");
                return 0;
            }
            
            hash = calculateHash(base64String, base64StringLen);
            hasHash = YES;
            
            if( n >= 3 ) //Check for volume
            {
                volume = lua_tonumber(L, 3);
            }
            
            ALBuffer* buffer = bufferCache.find(hash);
            if(buffer != nil)
            {
                cachedBuffer = buffer;
            }
            else
            {
                sfxrInstance.ResetParams();
                decodeParameters(base64String, &sfxrInstance);
                sfxrInstance.PlaySample();
            }
        }
        else if( strcmp(sound_type, "encode") == 0 )
        {
            sfxrInstance.ResetParams();   
            
            //Assuming the sound table is at index 2 ("encode" is at index 1)
            readTableIntoSFXRInstance(L, 2);  
            NSString *encoded = encodeParametersFull(&sfxrInstance);
            
            lua_pushstring(L, [encoded UTF8String]);
            return 1;            
        }
        else if( strcmp(sound_type, "decode") == 0 )
        {
            
        }        
        else
        {
            if (n >= 2) 
            {
                lua_Integer seed = luaL_checkint(L, 2);
                sfxrInstance.SetSeed((int)seed);

                if( n >= 3 ) //Check for volume
                {
                    volume = lua_tonumber(L, 3);
                }                
                
                if(calculateHashForSoundTypeAndSeed(sound_type, sound_type_len, seed, &hash))
                {
                    hasHash = YES;
                    
                    ALBuffer* buffer = bufferCache.find(hash);
                    if(buffer != nil)
                    {
                        cachedBuffer = buffer;
                    }
                }
            }
            
            if (cachedBuffer == nil) 
            {
                if (strcmp(sound_type, "random") == 0) 
                {
                    sfxrInstance.RandomizeButtonPressed();
                }
                else if(strcmp(sound_type, "jump")==0)
                {
                    sfxrInstance.JumpButtonPressed(); 
                }
                else if(strcmp(sound_type, "hit")==0)
                {
                    sfxrInstance.HitHurtButtonPressed();
                }
                else if(strcmp(sound_type, "pickup")==0)
                {
                    sfxrInstance.PickupCoinButtonPressed();
                }
                else if(strcmp(sound_type, "powerup")==0)
                {
                    sfxrInstance.PowerupButtonPressed();
                }
                else if(strcmp(sound_type, "shoot")==0)
                {
                    sfxrInstance.LaserShootButtonPressed();
                }
                else if(strcmp(sound_type, "explode")==0)
                {
                    sfxrInstance.ExplosionButtonPressed();
                }
                else if(strcmp(sound_type, "blit")==0)
                {
                    sfxrInstance.BlitSelectButtonPressed();
                }
                else
                {
                    return luaL_error(L, "sound type was not valid, %s given", sound_type);
                }
            }
        }   
    }
    
    
    if (cachedBuffer == nil) 
    {
        ALBuffer* playedBuffer = playSfxr(&sfxrInstance, volume);
        if (hasHash) 
        {
            //NSLog(@"adding sound to cache");
            bufferCache.add(playedBuffer, hash);
        }
    }
    else
    {
        //NSLog(@"playing sound from cache");
        playBuffer([OALSimpleAudio sharedInstance], cachedBuffer, volume);
    }
    
    //Hack to restore the randomness
    srand(randSeed);
    
    return 0;
}

void updateAudio()
{
}