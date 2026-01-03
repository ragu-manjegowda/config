use std::env;
use std::fs::OpenOptions;
use std::io::Write;
use std::path::PathBuf;
use std::process::Command;
use wordnet_db::WordNet;
use wordnet_types::{Pos, SynsetId};

fn log_debug(msg: &str) {
    if let Ok(home) = env::var("HOME") {
        let log_path = PathBuf::from(home).join(".cache/sioyek-dict.log");
        if let Ok(mut f) = OpenOptions::new().create(true).append(true).open(log_path) {
            let _ = writeln!(f, "{}", msg);
        }
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    log_debug(&format!("Args: {:?}", args));

    if args.len() < 3 {
        log_debug("Error: less than 3 args");
        return;
    }

    // Sioyek passes args with literal quotes, strip them
    let sioyek_path = args[1].trim_matches('"');
    let text = args[2].trim_matches('"').trim();
    log_debug(&format!("sioyek_path: {}, text: '{}'", sioyek_path, text));

    let word: String = text
        .chars()
        .take_while(|c| c.is_alphanumeric() || *c == '-')
        .collect();

    if word.is_empty() {
        set_status(sioyek_path, "No word selected");
        return;
    }

    match lookup_word(&word) {
        Some(def) => set_status(sioyek_path, &format!("{}: {}", word, def)),
        None => set_status(sioyek_path, &format!("No definition: {}", word)),
    }
}

fn lookup_word(word: &str) -> Option<String> {
    let home = env::var("HOME").ok()?;
    let wordnet_dir = PathBuf::from(home).join(".cache/nltk_data/corpora/wordnet");

    let wn = WordNet::load(&wordnet_dir).ok()?;
    let word_lower = word.to_lowercase();

    for (pos, pos_name) in [
        (Pos::Noun, "noun"),
        (Pos::Verb, "verb"),
        (Pos::Adj, "adj"),
        (Pos::Adv, "adv"),
    ] {
        if let Some(entry) = wn.index_entry(pos, &word_lower) {
            if let Some(&offset) = entry.synset_offsets.first() {
                let synset_id = SynsetId { pos, offset };
                if let Some(synset) = wn.get_synset(synset_id) {
                    let def = synset.gloss.definition;
                    return Some(format!("[{}] {}", pos_name, def));
                }
            }
        }
    }
    None
}

fn set_status(sioyek_path: &str, msg: &str) {
    let msg = if msg.len() > 200 { &msg[..200] } else { msg };
    let _ = Command::new(sioyek_path)
        .args([
            "--execute-command",
            "set_status_string",
            "--execute-command-data",
            msg,
        ])
        .spawn();
}
