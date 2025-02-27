# frozen_string_literal: true

describe Admin::Territories::MotifFieldsController, type: :controller do
  describe "#edit" do
    it "responds success" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [territory])
      sign_in agent
      get :edit, params: { territory_id: territory.id }
      expect(response).to be_successful
    end
  end

  describe "#update" do
    it "responds redirect" do
      territory = create(:territory)
      agent = create(:agent, role_in_territories: [territory])
      sign_in agent
      post :update, params: { territory_id: territory.id, territory: { enable_motif_categories_field: false } }
      expect(response).to redirect_to(edit_admin_territory_motif_fields_path(territory))
    end

    it "update territory" do
      territory = create(:territory, enable_motif_categories_field: true)
      agent = create(:agent, role_in_territories: [territory])
      sign_in agent

      expect do
        post :update, params: { territory_id: territory.id, territory: { enable_motif_categories_field: false } }
      end.to change { territory.reload.enable_motif_categories_field }.to(false)
    end
  end
end
