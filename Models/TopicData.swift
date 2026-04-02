import SwiftUI

struct TopicData {
    static let topics: [LearningTopic] = [
        LearningTopic(
            icon: "brain.head.profile", color: .themeBeige, title: "How Learning Works",
            shortDescription: "A simple guide to how your brain builds memories.",
            sections: [
                TopicSection(title: "1. Sensing the World", content: "It all starts with your senses! When you see, hear, smell, touch, or taste something new, that information rushes into your brain as electrical signals, looking for a place to go.", type: .paragraph),
                TopicSection(title: "2. The Messengers", content: "Meet your **neurons**! You have 86 billion of these tiny messengers in your head. The new sensory information forces them to start communicating with each other.", type: .paragraph),
                TopicSection(title: "3. The Spark!", content: "They don't actually touch! To send a message, they throw a cloud of chemical 'sparkles' across a tiny gap called a synapse. This quick flash is how **Short-Term Memories** are born.", type: .highlight),
                TopicSection(title: "4. Synaptic Plasticity", content: "When you repeat the same action, the signal passes through the same gap over and over. Your brain notices this and actually builds a thicker, stronger physical bridge between the two neurons!", type: .paragraph),
                TopicSection(title: "5. Practice Makes Perfect", content: "Here is the golden rule of learning: **Neurons that fire together, wire together!** Because the bridge is thicker, the signal can jump across effortlessly.", type: .paragraph),
                TopicSection(title: "6. The Support Crew", content: "Neurons don't work alone. Specialized 'Glial' cells float around to support them, delivering nutrients and clearing out waste so the connection stays healthy.", type: .paragraph),
                TopicSection(title: "7. The Superhighway", content: "Keep practicing, and your brain upgrades the road! Drag the Myelin onto the connection below to insulate the wire and make the signal zoom 100x faster!", type: .highlight),
                TopicSection(title: "8. Accelerated Signals", content: "With the myelin sheath applied, the electrical signal now bounces rapidly across the connection instead of walking. This is what muscle memory feels like biologically.", type: .paragraph),
                TopicSection(title: "9. Cleaning House", content: "Your brain is also a neat freak. See those gray, unused connections? If you stop practicing, your brain unplugs them to save energy. Focus is about **pruning** the noise!", type: .paragraph),
                TopicSection(title: "10. The Magic of Sleep", content: "Want a cheat code for learning? **Get some sleep!** While you snooze, your brain replays your day on fast-forward, sweeping away waste.", type: .paragraph),
                TopicSection(title: "11. Memory Consolidation", content: "During deep sleep, the short-term memories you formed today are physically migrated into long-term storage areas of the cortex.", type: .paragraph),
                TopicSection(title: "12. The 'Save Button'", content: "When you finally understand a concept, your brain releases a golden burst of **Dopamine**. It feels great, but more importantly, it acts like a giant 'SAVE' button, cementing the memory in place forever!", type: .highlight)
            ]
        ),
        LearningTopic(
            icon: "hourglass.circle.fill", color: .themeCream, title: "What is Procrastination?",
            shortDescription: "It's an emotional regulation problem, not a time management one.",
            sections: [
                TopicSection(title: "1. A Brain Regulation Problem", content: "Procrastination is not a time management problem — it's a brain regulation problem. The brain actively chooses short-term emotional relief over long-term goals.", type: .paragraph),
                TopicSection(title: "2. The CEO", content: "When you sit down to study, your Prefrontal Cortex (PFC), located at the front and upper side of your brain, is supposed to take charge and direct your focus.", type: .highlight),
                TopicSection(title: "3. The Daydreamer", content: "To focus, the CEO must suppress the Default Mode Network (DMN) — a scattered circuit responsible for daydreaming and mind-wandering.", type: .highlight),
                TopicSection(title: "4. The Alarm System", content: "Deep inside, near the center and base of the brain, sits the Amygdala, your brain's threat detector. When a task feels overwhelming or boring, it triggers a small but real fear response.", type: .highlight),
                TopicSection(title: "5. Losing Control", content: "In procrastination, the CEO fails. The DMN keeps firing, your mind drifts, and the Amygdala makes your brain instinctively avoid the textbook like physical danger.", type: .paragraph),
                TopicSection(title: "6. The Dopamine Trap", content: "Scrolling your phone produces quick, easy dopamine hits. Tap the digital distractions in the 3D view to clear them and force your brain to focus!", type: .highlight),
                TopicSection(title: "7. Instant vs. Delayed", content: "The brain compares the instant dopamine of your phone to the delayed payoff of studying (which arrives days later) and reliably chooses the immediate option.", type: .paragraph),
                TopicSection(title: "8. The Vicious Loop", content: "Over time, this trains the brain to avoid hard tasks even more, making procrastination a vicious, self-reinforcing biological loop.", type: .paragraph),
                TopicSection(title: "9. Breaking the Loop", content: "The fix? Lower the activation energy. Don't worry about 'motivation' — just make the task feel less threatening to the Amygdala.", type: .highlight),
                TopicSection(title: "10. The 2-Minute Rule", content: "Commit to doing just 2 minutes of the task. That's it. Just start writing one sentence or reading one page.", type: .paragraph),
                TopicSection(title: "11. Calming the Alarm", content: "Starting the task proves to the brain that the task isn't dangerous. This small action physically quiets the amygdala's alarm system.", type: .paragraph),
                TopicSection(title: "12. Regaining Focus", content: "With the alarm off, the Prefrontal Cortex can take over again, suppress the daydreaming circuit, and successfully sustain focus!", type: .highlight)
            ]
        ),
        LearningTopic(
            icon: "flame.fill", color: .themeLightBlue, title: "What is Burnout?",
            shortDescription: "Discover how chronic stress physically rewires your brain.",
            sections: [
                TopicSection(title: "1. The Brain Under Stress", content: "Study burnout is what happens when chronic academic stress slowly rewires and physically reshapes your brain, making thinking, remembering, and processing emotions progressively harder.", type: .paragraph),
                TopicSection(title: "2. Meet the CEO", content: "The Prefrontal Cortex (PFC), located at the front and upper side of your brain, is your brain's CEO. It handles planning, problem-solving, and keeping you focused.", type: .highlight),
                TopicSection(title: "3. Meet the Alarm", content: "Deep inside, near the center and base of the brain, sits the Amygdala, your threat detector. Normally, the CEO calms the Alarm down, but chronic stress disrupts this relationship.", type: .highlight),
                TopicSection(title: "4. The Healthy Baseline", content: "At a microscopic level, information flows smoothly between your neurons. Your CEO is in charge, and your learning pathways are clear.", type: .paragraph),
                TopicSection(title: "5. The Stress Trigger", content: "When you are constantly stressed by studying, your brain keeps releasing glucocorticoids (stress hormones like cortisol). In short bursts, these actually sharpen your focus.", type: .paragraph),
                TopicSection(title: "6. The Hormone Flood", content: "However, when they flood your brain day after day, they become toxic to neurons, especially in the areas dedicated to memory and focus.", type: .highlight),
                TopicSection(title: "7. Toxic Buildup", content: "The connection is jammed with stress molecules! Tap the red Cortisol buildup in the 3D view to clear the gap and let the signal pass!", type: .highlight),
                TopicSection(title: "8. The CEO Shrinks", content: "Under chronic stress, grey matter in your Prefrontal Cortex actually shrinks, and connections weaken. You must burn more mental energy to do tasks that used to feel easy.", type: .paragraph),
                TopicSection(title: "9. The Alarm Gets Stuck", content: "Burnout causes the Amygdala to physically enlarge and become hyperactive. You get stuck in a constant low-level alarm state, making you feel anxious and emotionally drained.", type: .highlight),
                TopicSection(title: "10. The Fog Rolls In", content: "These brain changes translate into very real symptoms: memory problems, attention lapses, and severe 'Brain Fog' where simple tasks feel mentally exhausting.", type: .paragraph),
                TopicSection(title: "11. The Breaking Point", content: "Eventually, neurons withdraw their receptors to protect themselves. Creativity drops, problem-solving is hit hard, and you experience emotional numbness.", type: .paragraph),
                TopicSection(title: "12. Rewiring for Recovery", content: "The good news? This is reversible. Genuine rest, sleep, and time away from stress flush out the toxic hormones, calm the Amygdala, and allow the CEO to rebuild!", type: .highlight)
            ]
        )
    ]
}
