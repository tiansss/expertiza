describe SignUpSheetController do
  let(:assignment) { build(:assignment, id: 1, instructor_id: 6, due_dates: [due_date], microtask: true, staggered_deadline: true) }
  let(:instructor) { build(:instructor, id: 6) }
  let(:student) { build(:student, id: 8) }
  let(:participant) { build(:participant, id: 1, user_id: 6, assignment: assignment) }
  let(:topic) { build(:topic, id: 1) }
  let(:signed_up_team) { build(:signed_up_team, team: team, topic: topic) }
  let(:signed_up_team2) { build(:signed_up_team, team_id: 2, is_waitlisted: true) }
  let(:team) { build(:assignment_team, id: 1, assignment: assignment) }
  let(:due_date) { build(:assignment_due_date, deadline_type_id: 1) }
  let(:due_date2) { build(:assignment_due_date, deadline_type_id: 2) }
  let(:bid) { Bid.new(topic_id: 1, priority: 1) }

  before(:each) do
    allow(Assignment).to receive(:find).with('1').and_return(assignment)
    allow(Assignment).to receive(:find).with(1).and_return(assignment)
    stub_current_user(instructor, instructor.role.name, instructor.role)
    allow(SignUpTopic).to receive(:find).with('1').and_return(topic)
    allow(Participant).to receive(:find_by).with(id: '1').and_return(participant)
    allow(AssignmentParticipant).to receive(:find).with('1').and_return(participant)
    allow(AssignmentParticipant).to receive(:find).with(1).and_return(participant)
  end

  describe '#new' do
    it 'builds a new sign up topic and renders sign_up_sheet#new page'
  end

  describe '#create' do
    context 'when topic cannot be found' do
      context 'when new topic can be saved successfully' do
        it 'sets up a new topic and redirects to assignment#edit page'
      end

      context 'when new topic cannot be saved successfully' do
        it 'sets up a new topic and renders sign_up_sheet#new page'
      end
    end

    context 'when topic can be found' do
      it 'updates the existing topic and redirects to sign_up_sheet#add_signup_topics_staggered page'
    end
  end

  describe '#destroy' do
    context 'when topic can be found' do
      it 'redirects to assignment#edit page'
    end

    context 'when topic cannot be found' do
      it 'shows an error flash message and redirects to assignment#edit page'
    end
  end

  describe '#edit' do
    it 'renders sign_up_sheet#edit page'
  end

  describe '#update' do
    context 'when topic cannot be found' do
      it 'shows an error flash message and redirects to assignment#edit page'
    end

    context 'when topic can be found' do
      it 'updates current topic and redirects to assignment#edit page'
    end
  end

  describe '#list' do
    let(:params) { { id: '1' } }
    let(:bids) { [bid] }
    let(:session){{user:student}}
    context 'when current assignment is intelligent assignment and has submission duedate (deadline_type_id 1)' do
      it 'renders sign_up_sheet#intelligent_topic_selection page' do
        allow(SignUpTopic).to receive(:find_slots_filled).with(1).and_return(topic)
        allow(SignUpTopic).to receive(:find_slots_waitlisted).with(1).and_return(topic)
        allow(SignUpTopic).to receive(:where).with(assignment_id: assignment.id, private_to:nil).and_return([topic])
        allow(assignment).to receive(:max_team_size).and_return(1)
        allow(participant).to receive(:team).and_return(team)

        allow(assignment).to receive(:is_intelligent).and_return(true)
        allow(Bid).to receive(:where).with(team_id: team.try(:id)).and_return(bids)
        allow(bids).to receive(:order).with(:priority).and_return(bids)
        allow(SignUpTopic).to receive(:find_by).with(id: bid.topic_id).and_return(topic)

        allow(assignment.due_dates).to receive(:find_by_deadline_type_id).with(7).and_return(nil)
        allow(assignment.due_dates).to receive(:find_by_deadline_type_id).with(6).and_return(nil)
        allow(assignment.due_dates).to receive(:find_by_deadline_type_id).with(1).and_return(due_date)

        allow(assignment).to receive(:staggered_deadline).and_return(true)
        allow(SignedUpTeam).to receive(:find_team_users).with(1,student.id).and_return([])

        get :list, params,session
        expect(response).to render_template(:intelligent_topic_selection)
      end
    end

    context 'when current assignment is not intelligent assignment and has submission duedate (deadline_type_id 1)' do
      it 'renders sign_up_sheet#list page' do
        allow(assignment).to receive(:is_intelligent).and_return(false)

        get :list, params,session
        expect(response).to render_template(:list)
      end
    end
  end

  describe '#sign_up' do
    let(:params) { { id: '1' } }
    let(:session){{user:student}}
    context 'when SignUpSheet.signup_team method return nil' do
      it 'shows an error flash message and redirects to sign_up_sheet#list page' do
        SignUpSheet.signup_team(@assignment.id, @user_id, params[:topic_id])
        allow(SignUpSheet).to receive(signup_team).with(any_args).and_return(nil)
        get :sign_up, params,session
        expect(response).to redirect_to action: 'list', id: params[:id]
        expect(flash.now[:error]).to eq("You've already signed up for a topic!")
      end
    end
  end

  describe '#signup_as_instructor_action' do
    let(:params) { { username: '1' } }
    context 'when user cannot be found' do
      it 'shows an flash error message and redirects to assignment#edit page' do
        allow(User).to receive(:find_by).with(any_args).and_return(nil)
        get :signup_as_instructor_action, params
        expect(flash.now[:error]).to eq("That student does not exist!")
      end
    end

    context 'when user can be found' do
      context 'when an assignment_participant can be found' do
        context 'when creating team related objects successfully' do
          it 'shows a flash success message and redirects to assignment#edit page' do

          end
        end

        context 'when creating team related objects unsuccessfully' do
          it 'shows a flash error message and redirects to assignment#edit page' do

          end
        end
      end

      context 'when an assignment_participant cannot be found' do
        it 'shows a flash error message and redirects to assignment#edit page' do

        end
      end
    end
  end  #by Tian

  describe '#delete_signup' do
    context 'when either submitted files or hyperlinks of current team are not empty' do
      it 'shows a flash error message and redirects to sign_up_sheet#list page'
    end

    context 'when both submitted files and hyperlinks of current team are empty and drop topic deadline is not nil and its due date has already passed' do
      it 'shows a flash error message and redirects to sign_up_sheet#list page'
    end

    context 'when both submitted files and hyperlinks of current team are empty and drop topic deadline is nil' do
      it 'shows a flash success message and redirects to sign_up_sheet#list page'
    end
  end

  describe '#delete_signup_as_instructor' do
    context 'when either submitted files or hyperlinks of current team are not empty' do
      it 'shows a flash error message and redirects to assignment#edit page'
    end

    context 'when both submitted files and hyperlinks of current team are empty and drop topic deadline is not nil and its due date has already passed' do
      it 'shows a flash error message and redirects to assignment#edit page'
    end

    context 'when both submitted files and hyperlinks of current team are empty and drop topic deadline is nil' do
      it 'shows a flash success message and redirects to assignment#edit page'
    end
  end

  describe '#set_priority' do
    it 'sets priority of bidding topic and redirects to sign_up_sheet#list page'
  end

  describe '#save_topic_deadlines' do
    context 'when topic_due_date cannot be found' do
      it 'creates a new topic_due_date record and redirects to assignment#edit page'
    end

    context 'when topic_due_date can be found' do
      it 'updates the existing topic_due_date record and redirects to assignment#edit page'
    end
  end

  describe '#show_team' do
    it 'renders show_team page'
  end

  describe '#switch_original_topic_to_approved_suggested_topic' do
    it 'redirects to sign_up_sheet#list page'
  end
end
