import json
import os
import pandas as pd
from typing import List, Dict, Optional
from tinytag import TinyTag

class Parser:
    def __init__(self, history_dir: str, music_dir: Optional[str] = None):
        self.history_dir = history_dir
        self.music_dir = music_dir
        self.raw_data: List[Dict] = []
        self.df: pd.DataFrame = pd.DataFrame()
        self.music_metadata: Dict[str, Dict] = {}

    def scan_music_directory(self):
        # Scans the music directory for audio files and extracts metadata.
        if not self.music_dir or not os.path.exists(self.music_dir):
            return

        supported_exts = {'.mp3', '.flac', '.m4a', '.wav', '.ogg', '.opus', '.aac', '.wma'}
        for root, _, files in os.walk(self.music_dir):
            for file in files:
                ext = os.path.splitext(file)[1].lower()
                if ext in supported_exts:
                    file_path = os.path.join(root, file)
                    try:
                        tag = TinyTag.get(file_path)
                        # Use lowercase filename without extension as key for better matching
                        base_name = os.path.splitext(file)[0].lower()
                        
                        # Add metadata for this base_name.
                        # Do not overwrite if we already found a valid track with this name 
                        # just in case of duplicates, though not strictly necessary.
                        if base_name not in self.music_metadata:
                            self.music_metadata[base_name] = {
                                'artist': tag.artist,
                                'album': tag.album,
                                'title': tag.title,
                                'duration': tag.duration or 0.0,
                                'genre': tag.genre
                            }
                    except Exception:
                        pass

    def load_all_history(self) -> pd.DataFrame:
        self.raw_data = []
        if not os.path.exists(self.history_dir):
            return pd.DataFrame()

        # Pre-scan music directory to build metadata mapping
        self.scan_music_directory()

        json_files = [f for f in os.listdir(self.history_dir) if f.endswith('.json')]
        
        for file_name in json_files:
            file_path = os.path.join(self.history_dir, file_name)
            try:
                with open(file_path, 'r', encoding='utf-8-sig') as f:
                    data = json.load(f)
                    if isinstance(data, list):
                        for item in data:
                            item['_source_file'] = file_name
                            self.raw_data.append(item)
            except Exception as e:
                pass

        self.df = pd.DataFrame(self.raw_data)

        # Deduplicate: remove records with the same (track, dateAdded)
        if not self.df.empty and 'track' in self.df.columns and 'dateAdded' in self.df.columns:
            before = len(self.df)
            # Ignore path, only use filename for dedup
            self.df['_track_basename'] = self.df['track'].apply(lambda x: os.path.basename(str(x)))
            self.df.drop_duplicates(subset=['_track_basename', 'dateAdded'], keep='first', inplace=True)
            self.df.drop(columns=['_track_basename'], inplace=True)
            self.df.reset_index(drop=True, inplace=True)
        
        if not self.df.empty:
            if 'dateAdded' in self.df.columns:
                sample_val = self.df['dateAdded'].dropna().iloc[0] if not self.df['dateAdded'].dropna().empty else 1e12
                unit = 'ms' if sample_val > 1e11 else 's'
                self.df['datetime'] = pd.to_datetime(self.df['dateAdded'], unit=unit)
            
            if 'track' in self.df.columns:
                self.df['track_name'] = self.df['track'].apply(lambda x: os.path.basename(str(x)))
                
                # Create a base column to match with music_metadata keys
                self.df['track_base'] = self.df['track_name'].apply(lambda x: os.path.splitext(x)[0].lower())

                # Map metadata into dataframe
                def get_meta(base_name, key, default):
                    if base_name in self.music_metadata:
                        val = self.music_metadata[base_name].get(key)
                        return val if pd.notnull(val) and val != '' else default
                    return default
                
                self.df['artist'] = self.df['track_base'].apply(lambda x: get_meta(x, 'artist', 'Unknown Artist'))
                self.df['album'] = self.df['track_base'].apply(lambda x: get_meta(x, 'album', 'Unknown Album'))
                self.df['title'] = self.df['track_base'].apply(lambda x: get_meta(x, 'title', None))
                self.df['duration'] = self.df['track_base'].apply(lambda x: get_meta(x, 'duration', 0.0))
                self.df['genre'] = self.df['track_base'].apply(lambda x: get_meta(x, 'genre', 'Unknown Genre'))
                
                # Fallback to track_name if title from tag is empty
                self.df['title'] = self.df.apply(lambda row: row['title'] if pd.notnull(row['title']) else row['track_name'], axis=1)

        return self.df

    def get_summary(self):
        if self.df is None or self.df.empty:
            return {"error": "No data"}
        
        track_col = 'title' if 'title' in self.df.columns else ('track_name' if 'track_name' in self.df.columns else None)
        
        # 1. Core numbers
        most_played = {}
        if track_col:
            most_played = {str(k): int(v) for k, v in self.df[track_col].value_counts().head(500).items()}

        total_hours = 0.0
        if 'duration' in self.df.columns:
            total_hours = float((self.df['duration'].sum()) / 3600.0)
            
        unique_artists = int(self.df['artist'].nunique()) if 'artist' in self.df.columns else 0
        unique_albums = int(self.df['album'].nunique()) if 'album' in self.df.columns else 0
        
        favorite_genre = "Unknown Genre"
        if 'genre' in self.df.columns:
            valid_genres = self.df[self.df['genre'] != 'Unknown Genre']
            if not valid_genres.empty:
                favorite_genre = str(valid_genres['genre'].value_counts().idxmax())
                
        # 2. Top Rankings
        top_artists = {}
        if 'artist' in self.df.columns:
            valid_artists = self.df[self.df['artist'] != 'Unknown Artist']
            top_artists = {str(k): int(v) for k, v in valid_artists['artist'].value_counts().head(200).items()}

        top_albums = {}
        if 'album' in self.df.columns:
            valid_albums = self.df[~self.df['album'].isin(['Unknown Album', ''])]
            top_albums = {str(k): int(v) for k, v in valid_albums['album'].value_counts().head(200).items()}
            
        monthly_top_song = {}
        if 'datetime' in self.df.columns and track_col:
            self.df['month_key'] = self.df['datetime'].dt.strftime('%Y-%m')
            for name, group in self.df.groupby('month_key'):
                top_song = group[track_col].value_counts().idxmax()
                monthly_top_song[str(name)] = str(top_song)

        # 3. Time Dimension
        play_history_by_date = {}
        listening_periods = {"night": 0, "morning": 0, "afternoon": 0, "evening": 0}
        weekly_pattern = {"Mon": 0, "Tue": 0, "Wed": 0, "Thu": 0, "Fri": 0, "Sat": 0, "Sun": 0}
        
        if 'datetime' in self.df.columns:
             self.df['date_only'] = self.df['datetime'].dt.strftime('%Y-%m-%d')
             play_history_by_date = {str(k): int(v) for k, v in self.df['date_only'].value_counts().sort_index().items()}
             
             hours = self.df['datetime'].dt.hour
             listening_periods["night"] = int(((hours >= 0) & (hours < 6)).sum())
             listening_periods["morning"] = int(((hours >= 6) & (hours < 12)).sum())
             listening_periods["afternoon"] = int(((hours >= 12) & (hours < 18)).sum())
             listening_periods["evening"] = int(((hours >= 18) & (hours <= 23)).sum())
             
             day_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
             day_counts = self.df['datetime'].dt.dayofweek.value_counts()
             for day_idx, count in day_counts.items():
                 weekly_pattern[day_names[day_idx]] = int(count)

        # 4. Special highlights
        single_day_repeat_max = {"date": "", "track": "", "count": 0}
        if 'date_only' in self.df.columns and track_col:
            daily_counts = self.df.groupby(['date_only', track_col]).size()
            if not daily_counts.empty:
                max_idx = daily_counts.idxmax()
                single_day_repeat_max = {
                    "date": str(max_idx[0]),
                    "track": str(max_idx[1]),
                    "count": int(daily_counts.max())
                }

        latest_night_song = {"time": "", "track": ""}
        if 'datetime' in self.df.columns and track_col:
            night_df = self.df[(self.df['datetime'].dt.hour >= 0) & (self.df['datetime'].dt.hour < 6)].copy()
            if not night_df.empty:
                night_df['time_only'] = night_df['datetime'].dt.time
                latest_row = night_df.loc[night_df['time_only'].astype(str).idxmax()]
                latest_night_song = {
                     "time": latest_row['datetime'].strftime('%Y-%m-%d %H:%M:%S'),
                     "track": str(latest_row[track_col])
                }
                
        most_immersive_day = {"date": "", "count": 0}
        total_days = 0
        if play_history_by_date:
            total_days = len(play_history_by_date)
            max_day = max(play_history_by_date, key=play_history_by_date.get)
            most_immersive_day = {"date": str(max_day), "count": int(play_history_by_date[max_day])}
            
        avg_daily_minutes = 0
        if total_days > 0:
            avg_daily_minutes = int(round((total_hours * 60.0) / total_days))

        # 5. Track Details for top tracks
        track_details = {}
        if track_col and 'datetime' in self.df.columns and 'date_only' in self.df.columns:
            # Generate details only for the top ones to avoid huge JSON payload
            for t_name in list(most_played.keys())[:300]:
                t_df = self.df[self.df[track_col] == t_name]
                if not t_df.empty:
                    first_play = str(t_df['datetime'].min().strftime('%Y-%m-%d %H:%M:%S'))
                    last_play = str(t_df['datetime'].max().strftime('%Y-%m-%d %H:%M:%S'))
                    history = {str(k): int(v) for k, v in t_df['date_only'].value_counts().sort_index().items()}
                    track_details[t_name] = {
                        "first_play": first_play,
                        "last_play": last_play,
                        "history": history,
                        "total_plays": int(len(t_df))
                    }

        # 6. Artist Details
        artist_details = {}
        if 'artist' in self.df.columns and 'datetime' in self.df.columns and 'date_only' in self.df.columns:
            for a_name in list(top_artists.keys())[:200]:
                a_df = self.df[self.df['artist'] == a_name]
                if not a_df.empty:
                    first_play = str(a_df['datetime'].min().strftime('%Y-%m-%d %H:%M:%S')) if not a_df['datetime'].dropna().empty else "Unknown"
                    last_play = str(a_df['datetime'].max().strftime('%Y-%m-%d %H:%M:%S')) if not a_df['datetime'].dropna().empty else "Unknown"
                    history = {str(k): int(v) for k, v in a_df['date_only'].value_counts().sort_index().items()}
                    
                    top_songs = {}
                    if track_col:
                        top_songs = {str(k): int(v) for k, v in a_df[track_col].value_counts().head(10).items()}

                    artist_details[str(a_name)] = {
                        "first_play": first_play,
                        "last_play": last_play,
                        "history": history,
                        "total_plays": int(len(a_df)),
                        "top_songs": top_songs
                    }

        # 7. Album Details
        album_details = {}
        if 'album' in self.df.columns and 'datetime' in self.df.columns and 'date_only' in self.df.columns:
            for al_name in list(top_albums.keys())[:200]:
                al_df = self.df[self.df['album'] == al_name]
                if not al_df.empty:
                    first_play = str(al_df['datetime'].min().strftime('%Y-%m-%d %H:%M:%S')) if not al_df['datetime'].dropna().empty else "Unknown"
                    last_play = str(al_df['datetime'].max().strftime('%Y-%m-%d %H:%M:%S')) if not al_df['datetime'].dropna().empty else "Unknown"
                    history = {str(k): int(v) for k, v in al_df['date_only'].value_counts().sort_index().items()}

                    top_songs = {}
                    if track_col:
                        top_songs = {str(k): int(v) for k, v in al_df[track_col].value_counts().head(10).items()}

                    album_details[str(al_name)] = {
                        "first_play": first_play,
                        "last_play": last_play,
                        "history": history,
                        "total_plays": int(len(al_df)),
                        "top_songs": top_songs
                    }

        summary = {
            "total_plays": int(len(self.df)),
            "total_days": total_days,
            "avg_daily_minutes": avg_daily_minutes,
            "unique_tracks": int(self.df['track_base'].nunique() if 'track_base' in self.df.columns else 0),
            "most_played": dict(most_played),
            "play_history_by_date": dict(play_history_by_date),
            "total_hours": round(total_hours, 1),
            "unique_artists": unique_artists,
            "unique_albums": unique_albums,
            "favorite_genre": favorite_genre,
            "top_artists": dict(top_artists),
            "top_albums": dict(top_albums),
            "monthly_top_song": monthly_top_song,
            "listening_periods": listening_periods,
            "weekly_pattern": weekly_pattern,
            "single_day_repeat_max": single_day_repeat_max,
            "latest_night_song": latest_night_song,
            "most_immersive_day": most_immersive_day,
            "track_details": track_details,
            "artist_details": artist_details,
            "album_details": album_details
        }
        return summary

    def get_all_summaries(self):
        summaries = {}
        original_df = self.df.copy() if hasattr(self, 'df') and not self.df.empty else pd.DataFrame()
        
        # All Time
        self.df = original_df.copy()
        summaries['所有时间'] = self.get_summary()
        
        # By Year
        if not original_df.empty and 'datetime' in original_df.columns:
            original_df['year_key'] = original_df['datetime'].dt.year.astype(str) + "年"
            for year, group in original_df.groupby('year_key'):
                self.df = group.copy()
                summaries[str(year)] = self.get_summary()
        
        # Restore
        self.df = original_df
        return summaries
